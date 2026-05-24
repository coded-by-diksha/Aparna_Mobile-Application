const profile = require('../model/profile');
const multer = require('multer');
const { uploadBuffer } = require('../utils/cloudinaryUpload');

const upload = multer({ 
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: function (req, file, cb) {
        const filetypes = /jpeg|jpg|png|gif|webp/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(file.originalname.toLowerCase());
        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Only image files are allowed!'));
    }
});

exports.uploadMiddleware = (req, res, next) => {
    upload.single('profilephoto')(req, res, (err) => {
        if (!err) return next();

        if (err instanceof multer.MulterError) {
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({
                    error: 'Image is too large. Max allowed size is 5MB.',
                    success: false,
                });
            }

            return res.status(400).json({
                error: err.message || 'Invalid image upload request.',
                success: false,
            });
        }

        return res.status(400).json({
            error: err.message || 'Invalid image file.',
            success: false,
        });
    });
};

// Get user profile by ID
exports.getUserProfile = async (req, res) => {
    try{
        const { user_id } = req.params;
        
        // Get user to verify they exist
        const user = await profile.getUserProfile(user_id);
        if (!user) {
            return res.status(404).json({ 
                error: 'User not found',
                success: false 
            });
        }
        
        return res.status(200).json({
            message: 'User profile retrieved successfully',
            profile: user,
            success: true
        });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        return res.status(500).json({
            error: 'Failed to get user profile',
            success: false
        });
    }
}


exports.updateUserProfile = async (req, res) => {
    try {
        const { user_id } = req.params;
        const profileData = req.body;
        // Get user to verify they exist
        const user = await profile.getUserProfile(user_id);
        if (!user) {
            return res.status(404).json({
                error: 'User not found',
                success: false
            });
        }
        // Update user profile
        const updatedProfile = await profile.updateUserProfile(user_id, profileData);
        return res.status(200).json({
            message: 'User profile updated successfully',
            profile: updatedProfile,
            success: true
        });
    } catch (error) {
        console.error('Error updating user profile:', error);
        return res.status(500).json({   
            error: 'Failed to update user profile',
            success: false
        });
    }
};
exports.addprofileImage = async (req, res) => {
    try {
        const { user_id } = req.params;

        // Check if file was uploaded
        if (!req.file || !req.file.buffer) {
            return res.status(400).json({
                error: 'No image file provided',
                success: false
            });
        }

        // Get user to verify they exist
        const user = await profile.getUserProfile(user_id);
        if (!user) {
            return res.status(404).json({
                error: 'User not found',
                success: false
            });
        }

        // Upload to Cloudinary
        const profilephoto = await uploadBuffer(
            req.file.buffer,
            req.file.mimetype,
            'profiles',
            `profile_${user_id}`,
            { keepSingleAsset: true }
        );

        console.log('Saving profile photo URL:', profilephoto);
        console.log('For user_id:', user_id);
        
        // Update profile photo
        const updatedProfilePhoto = await profile.updateProfilePhoto(user_id, profilephoto);
        console.log('Updated profile result:', updatedProfilePhoto);
        
        return res.status(200).json({
            message: 'Profile photo updated successfully',
            profile: updatedProfilePhoto,
            success: true
        });
    } catch (error) {
        console.error('Error updating profile photo:', error);

        return res.status(500).json({
            error: 'Failed to update profile photo',
            details: process.env.NODE_ENV === 'production' ? undefined : error?.message,
            success: false
        });
    }
};
