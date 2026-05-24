const pool = require('../config/database');

class Category {
    static async getAllCategories() {
        try {
            const query = 'SELECT * FROM blog_categories ORDER BY name ASC';
            const result = await pool.query(query);
            return result.rows;
        } catch (error) {
            console.error('Error fetching categories:', error);
            throw error;
        }
    }

    static async updateCategoryIcon(id, icon_url) {
        try {
            const query = 'UPDATE blog_categories SET icon_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *';
            const result = await pool.query(query, [icon_url, id]);
            return result.rows[0];
        } catch (error) {
            console.error('Error updating category:', error);
            throw error;
        }
    }

    static async createCategory(name, icon_url) {
        try {
            const query = 'INSERT INTO blog_categories (name, icon_url) VALUES ($1, $2) RETURNING *';
            const result = await pool.query(query, [name, icon_url]);
            return result.rows[0];
        } catch (error) {
            console.error('Error creating category:', error);
            throw error;
        }
    }
}

module.exports = Category;
