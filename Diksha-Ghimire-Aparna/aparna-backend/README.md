# aparna
This is a backend of the period tracking application which is yet to be build.

## Environment Variables

### For Local Media Uploads

Uploaded images and videos are stored locally under `uploads/` and served by the backend.

No Cloudinary environment variables are required.

### For Firebase (Push Notifications on Render)

Firebase requires a service account key with proper handling of the private key newlines on Render.

**Recommended approach: Use `FIREBASE_PRIVATE_KEY_BASE64`**

```bash
# Generate the encoded credentials locally:
node scripts/setup-firebase-env.js
```

This script will:
1. Read your `config/serviceAccountKey.json`
2. Base64-encode it
3. Output the environment variables to set on Render

**Then on Render, set:**
- `FIREBASE_PRIVATE_KEY_BASE64` – (base64-encoded serviceAccountKey.json)
- `FIREBASE_PROJECT_ID` – (from your service account)
- `FIREBASE_CLIENT_EMAIL` – (from your service account)

The backend will automatically decode the base64 string and initialize Firebase.

**Alternative: Use `FIREBASE_PRIVATE_KEY` with escaped newlines**

If you prefer not to use base64, set `FIREBASE_PRIVATE_KEY` with `\\n` (double-backslash) for newlines in the raw JSON, but this is error-prone on Render and not recommended.
