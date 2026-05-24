const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});


async function uploadBuffer(buffer, mimeType, folder, prefix, options = {}) {
  const keepSingleAsset = Boolean(options.keepSingleAsset);

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `aparna/${folder}`,
        public_id: keepSingleAsset ? prefix : `${prefix}_${Date.now()}`,
        overwrite: keepSingleAsset,
        invalidate: keepSingleAsset,
        unique_filename: !keepSingleAsset,
        resource_type: 'auto', // Automatically detect resource type (image/video)
        timeout: 60000,
      },
      (error, result) => {
        if (error) {
          reject(new Error(`Cloudinary upload error: ${error.message}`));
        } else {
          resolve(result.secure_url);
        }
      }
    );

    stream.end(buffer);
  });
}

/**
 * Upload a base64 image to Cloudinary
 * @param {string} base64String - Base64 encoded image (with or without data URI)
 * @param {string} folder - Cloudinary folder name
 * @param {string} prefix - File name prefix
 * @returns {Promise<string|null>} URL of the uploaded file or null if invalid
 */
async function uploadBase64Image(base64String, folder, prefix) {
  if (!base64String || typeof base64String !== 'string') {
    return null;
  }

  try {
    // Handle data URI format (e.g., "data:image/jpeg;base64,...")
    let dataUri = base64String;
    if (!base64String.startsWith('data:')) {
      dataUri = `data:image/jpeg;base64,${base64String}`;
    }

    const result = await cloudinary.uploader.upload(dataUri, {
      folder: `aparna/${folder}`,
      public_id: `${prefix}_${Date.now()}`,
      resource_type: 'auto',
      timeout: 60000,
    });

    return result.secure_url;
  } catch (error) {
    console.error('Cloudinary base64 upload error:', error);
    throw new Error(`Failed to upload base64 image: ${error.message}`);
  }
}

/**
 * Delete an image from Cloudinary by URL
 * @param {string} url - The Cloudinary URL to delete
 * @returns {Promise<void>}
 */
async function deleteImage(url) {
  if (!url || typeof url !== 'string') {
    return;
  }

  try {
    const parsedUrl = new URL(url);
    const uploadMarker = '/upload/';
    const uploadIndex = parsedUrl.pathname.indexOf(uploadMarker);
    if (uploadIndex === -1) {
      console.warn('Could not extract public_id from URL:', url);
      return;
    }

    // Example path after marker: v123/aparna/profiles/file_name.jpg
    let publicPath = parsedUrl.pathname.substring(uploadIndex + uploadMarker.length);
    if (/^v\d+\//.test(publicPath)) {
      publicPath = publicPath.replace(/^v\d+\//, '');
    }

    const extensionIndex = publicPath.lastIndexOf('.');
    const publicId = extensionIndex === -1
      ? publicPath
      : publicPath.substring(0, extensionIndex);

    if (!publicId) {
      console.warn('Could not extract public_id from URL:', url);
      return;
    }

    await cloudinary.uploader.destroy(publicId);
    console.log(`Deleted image from Cloudinary: ${publicId}`);
  } catch (error) {
    console.error('Error deleting image from Cloudinary:', error);
    // Don't throw - deletion failure shouldn't break the main operation
  }
}

module.exports = {
  uploadBuffer,
  uploadBase64Image,
  deleteImage,
};
