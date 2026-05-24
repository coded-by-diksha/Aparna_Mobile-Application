const express = require('express');
const router = express.Router();
const blogController = require('../controller/blogController');
const storyController = require('../controller/storyController');

const authenticateToken = require('../middleware/jwtmiddleware');

const CategoryController = require('../controller/category_controller');

router.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// Category routes
router.get('/categories', CategoryController.getAllCategories);
router.post('/categories', authenticateToken, CategoryController.createCategory);
router.put('/categories/:id', authenticateToken, CategoryController.updateCategoryIcon);

// Public routes
router.get('/', blogController.getBlog);
router.get('/random', blogController.getRandomBlogs);
router.get('/:id', blogController.getBlogById);
router.post('/view/:id', blogController.recordBlogView);

// Protected routes
router.post('/', authenticateToken, blogController.uploadMiddleware, blogController.createBlog);
router.put('/:id', authenticateToken, blogController.uploadMiddleware, blogController.updateBlog);
router.delete('/:id', authenticateToken, blogController.deleteBlog);

// Story routes
router.get('/stories/all', storyController.getAllStories);
router.post('/stories/create', authenticateToken, storyController.createStory);
router.delete('/stories/:id', authenticateToken, storyController.deleteStory);

module.exports = router;
