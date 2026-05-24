const fs = require('fs/promises');
const path = require('path');

const uploadsRoot = path.join(__dirname, '..', 'uploads');

function sanitizeSegment(value, fallback) {
  if (!value || typeof value !== 'string') return fallback;
  const sanitized = value.replace(/[^a-zA-Z0-9_-]/g, '');
  return sanitized || fallback;
}

function extFromMime(mimeType, fallback = 'jpg') {
  if (!mimeType || typeof mimeType !== 'string') return fallback;
  const ext = mimeType.split('/')[1] || fallback;
  return sanitizeSegment(ext, fallback).toLowerCase();
}

function buildAbsoluteUrl(req, relativePath) {
  const protocol = req.protocol || 'http';
  const host = req.get('host');
  return `${protocol}://${host}/${relativePath.replace(/^\/+/, '')}`;
}

async function saveBufferAsUpload(req, buffer, mimeType, folder, prefix) {
  const safeFolder = sanitizeSegment(folder, 'profiles');
  const targetDir = path.join(uploadsRoot, safeFolder);
  await fs.mkdir(targetDir, { recursive: true });

  const extension = extFromMime(mimeType, 'jpg');
  const safePrefix = sanitizeSegment(prefix, 'upload');
  const fileName = `${safePrefix}_${Date.now()}.${extension}`;
  const filePath = path.join(targetDir, fileName);
  await fs.writeFile(filePath, buffer);

  const publicPath = `uploads/${safeFolder}/${fileName}`;
  return buildAbsoluteUrl(req, publicPath);
}

async function saveBase64Image(req, base64String, folder, prefix) {
  if (!base64String || typeof base64String !== 'string') {
    return null;
  }

  const hasDataUri = base64String.startsWith('data:');
  let mimeType = 'image/jpeg';
  let payload = base64String;

  if (hasDataUri) {
    const commaIndex = base64String.indexOf(',');
    const meta = base64String.substring(0, commaIndex);
    payload = base64String.substring(commaIndex + 1);
    const mimeMatch = meta.match(/^data:([^;]+);base64$/i);
    if (mimeMatch && mimeMatch[1]) {
      mimeType = mimeMatch[1].toLowerCase();
    }
  }

  const buffer = Buffer.from(payload, 'base64');
  return saveBufferAsUpload(req, buffer, mimeType, folder, prefix);
}

async function deleteLocalAssetByUrl(assetUrl) {
  if (!assetUrl || typeof assetUrl !== 'string') return;

  let pathname;
  try {
    pathname = new URL(assetUrl).pathname;
  } catch (_) {
    pathname = assetUrl;
  }

  const normalizedPath = pathname.replace(/^\/+/, '').replace(/\\/g, '/');
  if (!normalizedPath.startsWith('uploads/')) return;

  const relativePath = normalizedPath.replace(/^uploads\//, '');
  const targetPath = path.resolve(uploadsRoot, relativePath);
  const expectedPrefix = path.resolve(uploadsRoot) + path.sep;

  if (!targetPath.startsWith(expectedPrefix)) {
    return;
  }

  try {
    await fs.unlink(targetPath);
  } catch (error) {
    if (error && error.code !== 'ENOENT') {
      throw error;
    }
  }
}

module.exports = {
  saveBufferAsUpload,
  saveBase64Image,
  deleteLocalAssetByUrl,
};