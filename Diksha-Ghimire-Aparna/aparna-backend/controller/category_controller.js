const Category = require('../model/Category');

class CategoryController {
    static async getAllCategories(req, res) {
        try {
            const categories = await Category.getAllCategories();
            res.status(200).json(categories);
        } catch (error) {
            console.error('Error fetching categories:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async updateCategoryIcon(req, res) {
        const { id } = req.params;
        const { icon_url } = req.body;

        try {
            const updatedCategory = await Category.updateCategoryIcon(id, icon_url);
            if (!updatedCategory) {
                return res.status(404).json({ error: 'Category not found' });
            }
            res.status(200).json(updatedCategory);
        } catch (error) {
            console.error('Error updating category:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async createCategory(req, res) {
        const { name, icon_url } = req.body;
        try {
            const newCategory = await Category.createCategory(name, icon_url);
            res.status(201).json(newCategory);
        } catch (error) {
            console.error('Error creating category:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}

module.exports = CategoryController;
