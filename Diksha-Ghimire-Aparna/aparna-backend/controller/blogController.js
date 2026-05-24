const blog = require('../model/blogs');
const multer = require('multer');
const NotificationHelper = require('../utils/notificationHelper');
const { uploadBuffer, deleteImage } = require('../utils/cloudinaryUpload');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit (increased for video)
    fileFilter: function (req, file, cb) {
        const filetypes = /jpeg|jpg|png|gif|webp|mp4|mov|avi|mkv/;
        const mimetype = filetypes.test(file.mimetype);
        const extname = filetypes.test(file.originalname.toLowerCase());

        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Only image and video files are allowed!'));
    }
});

// Middleware for handling multiple files
const uploadMiddleware = upload.fields([
    { name: 'images', maxCount: 10 },
    { name: 'video', maxCount: 1 }
]);

async function uploadFilesToCloudinary(files, folder, prefix) {
    const uploadedFiles = [];

    try {
        for (const file of files) {
            const fileUrl = await uploadBuffer(
                file.buffer,
                file.mimetype,
                folder,
                prefix
            );
            uploadedFiles.push(fileUrl);
        }

        return uploadedFiles;
    } catch (error) {
        // Attempt to clean up uploaded files on error
        await Promise.allSettled(
            uploadedFiles.map((url) => deleteImage(url))
        );
        throw error;
    }
}

function normalizeBlogMedia(value) {
    if (!value) {
        return [];
    }

    return Array.isArray(value) ? value : [value];
}

function normalizeIncomingImageField(value) {
    if (!value) return [];
    if (Array.isArray(value)) return value;

    if (typeof value === 'string') {
        const trimmed = value.trim();
        if (!trimmed) return [];

        if (trimmed.startsWith('[')) {
            try {
                const parsed = JSON.parse(trimmed);
                return Array.isArray(parsed) ? parsed : [trimmed];
            } catch (_) {
                return [trimmed];
            }
        }

        return [trimmed];
    }

    return [];
}

const blogController = {
    uploadMiddleware,

    async createBlog(req, res) {
        try {
            // Process uploaded files
            // req.files is an object with keys 'images' and 'video' if fields are used
            const imageFiles = req.files && req.files['images']
                ? await uploadFilesToCloudinary(req.files['images'], 'blogs', 'blog_image')
                : [];
            const videoFiles = req.files && req.files['video']
                ? await uploadFilesToCloudinary(req.files['video'], 'blogs', 'blog_video')
                : [];
            const videoFile = videoFiles[0] || null;

            const blogData = await blog.createBlog(
                {
                    userid: req.body.userid,
                    title: req.body.title,
                    content: req.body.content,
                    images: imageFiles,
                    video: videoFile,
                    category_id: req.body.category_id,
                    lang_id: req.body.lang_id
                }
            );

            // Send notification to all users about the new blog (include category; timestamp is added by FCM service)
            const authorName = req.body.author_name || 'Aparna';
            const category = req.body.category_name || req.body.category || (blogData.category_id != null ? String(blogData.category_id) : '') || 'General';
            NotificationHelper.notifyNewBlog(req.body.title, blogData.id, authorName, category)
                .then(result => {
                    console.log(`✅ Blog notification sent: ${result.successCount} successful, ${result.failureCount} failed`);
                })
                .catch(error => {
                    console.error('❌ Error sending blog notification:', error);
                });

            res.status(201).json(blogData);
        } catch (error) {
            console.error('Error creating blog:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async getBlog(req, res) {
        try {
            // Check for token manually to decide what to show
            const authHeader = req.headers['authorization'];
            const token = authHeader && authHeader.split(' ')[1];
            let isAdmin = false;

            if (token) {
                try {
                    const decoded = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
                    if (decoded.role === 'admin') {
                        isAdmin = true;
                    }
                } catch (err) {
                    // Token invalid or expired, treat as normal user
                }
            }

            const blogs = await blog.getBlog();

            if (isAdmin) {
                const adminBlogs = await blog.getBlogAdmin();
                res.status(200).json(adminBlogs);
            } else {
                const formattedBlogs = blogs.map(b => ({
                    id: b.id,
                    title: b.title,
                    content: b.content,
                    images: b.images,
                    video: b.video,
                    category_id: b.category_id,
                    categoryName: b.categoryName,
                    categoryIcon: b.categoryIcon,
                    createdat: b.createdat,
                    updatedat: b.updatedat,
                    authorName: b.authorName || 'Aparna',
                    views: b.views
                }));
                res.status(200).json(formattedBlogs);
            }
        } catch (error) {
            console.error('Error fetching blog:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async getBlogById(req, res) {
        try {
            const authHeader = req.headers['authorization'];
            const token = authHeader && authHeader.split(' ')[1];
            let isAdmin = false;

            if (token) {
                try {
                    const decoded = require('jsonwebtoken').verify(token, process.env.JWT_SECRET);
                    if (decoded.role === 'admin') {
                        isAdmin = true;
                    }
                } catch (err) {
                    // Token invalid/expired
                }
            }

            const blogData = await blog.getBlogById(req.params.id);

            if (!blogData) {
                return res.status(404).json({ error: 'Blog not found' });
            }

            if (isAdmin) {
                const adminBlogData = await blog.getBlogByIdAdmin(req.params.id);
                res.status(200).json(adminBlogData);
            } else {
                const formattedBlog = {
                    id: blogData.id,
                    title: blogData.title,
                    content: blogData.content,
                    images: blogData.images,
                    video: blogData.video,
                    category_id: blogData.category_id,
                    categoryName: blogData.categoryName,
                    categoryIcon: blogData.categoryIcon,
                    createdat: blogData.createdat,
                    updatedat: blogData.updatedat,
                    authorName: blogData.authorName || 'Aparna',
                    views: blogData.views
                };
                res.status(200).json(formattedBlog);
            }
        } catch (error) {
            console.error('Error fetching blog by ID:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async updateBlog(req, res) {
        try {
            const existingBlog = await blog.getBlogById(req.params.id);

            const imageFiles = req.files && req.files['images']
                ? await uploadFilesToCloudinary(req.files['images'], 'blogs', 'blog_image')
                : undefined;
            const videoFiles = req.files && req.files['video']
                ? await uploadFilesToCloudinary(req.files['video'], 'blogs', 'blog_video')
                : undefined;
            const videoFile = videoFiles ? videoFiles[0] : undefined;

            const updateData = {
                userid: req.body.userid,
                title: req.body.title,
                content: req.body.content,
                category_id: req.body.category_id,
                lang_id: req.body.lang_id,
            };

            if (imageFiles) {
                updateData.images = imageFiles;
            } else if (req.body.images) {
                updateData.images = normalizeIncomingImageField(req.body.images);
            }

            if (videoFile !== undefined) {
                updateData.video = videoFile;
            } else if (req.body.video) {
                updateData.video = req.body.video;
            }

            const blogData = await blog.updateBlog(req.params.id, updateData);

            if (imageFiles && existingBlog?.images) {
                await Promise.allSettled(
                    normalizeBlogMedia(existingBlog.images).map((url) => deleteImage(url))
                );
            }

            if (videoFile !== undefined && existingBlog?.video) {
                await deleteImage(existingBlog.video);
            }

            res.status(200).json(blogData);
        } catch (error) {
            console.error('Error updating blog:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async deleteBlog(req, res) {
        try {
            const { id } = req.params;
            console.log(`Attempting to delete blog with ID: ${id}`);
            const existingBlog = await blog.getBlogById(id);
            const blogData = await blog.deleteBlog(id);

            if (existingBlog?.images) {
                await Promise.allSettled(
                    normalizeBlogMedia(existingBlog.images).map((url) => deleteImage(url))
                );
            }

            if (existingBlog?.video) {
                await deleteImage(existingBlog.video);
            }

            console.log(`Successfully deleted blog: ${id}`);
            res.status(200).json({ success: true, message: 'Blog deleted successfully', data: blogData });
        } catch (error) {
            console.error('Error deleting blog:', error);
            const statusCode = error.message === 'Blog not found' ? 404 : 500;
            res.status(statusCode).json({ 
                success: false,
                error: error.message || 'Internal server error' 
            });
        }
    },
    async getRandomBlogs(req, res) {
        try {
            const limit = parseInt(req.query.limit) || 2;
            const blogs = await blog.getRandomBlogs(limit);
            const formattedBlogs = blogs.map(b => ({
                id: b.id,
                title: b.title,
                content: b.content,
                images: b.images,
                video: b.video,
                category: b.categoryName, // Use categoryName from join
                categoryIcon: b.categoryIcon,
                createdat: b.createdat,
                updatedat: b.updatedat,
                author: b.authorName || 'Aparna',
                views: b.views || 0
            }));
            res.status(200).json(formattedBlogs);
        } catch (error) {
            console.error('Error fetching random blogs:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
    async recordBlogView(req, res) {
        try {
            const blogId = req.params.id;
            const userId = req.body.userid; // Passed from frontend if logged in

            await blog.recordBlogView(blogId, userId);
            res.status(200).json({ success: true, message: 'View recorded' });
        } catch (error) {
            console.error('Error recording blog view:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
};

module.exports = blogController;