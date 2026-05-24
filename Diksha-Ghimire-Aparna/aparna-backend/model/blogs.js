const pool = require('../config/database');

let imagesColumnTypePromise = null;

async function getImagesColumnType() {
    if (!imagesColumnTypePromise) {
        imagesColumnTypePromise = (async () => {
            try {
                const result = await pool.query(
                    `
                    SELECT udt_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Blog'
                      AND column_name = 'images'
                    LIMIT 1
                    `
                );

                return result.rows[0]?.udt_name || 'text';
            } catch (error) {
                console.warn('Could not detect Blog.images column type, defaulting to text:', error.message);
                return 'text';
            }
        })();
    }

    return imagesColumnTypePromise;
}

function toImageArray(images) {
    if (!images) return [];
    if (Array.isArray(images)) return images.filter(Boolean);

    if (typeof images === 'string') {
        const trimmed = images.trim();
        if (!trimmed) return [];

        // JSON format, e.g. ["https://..."]
        if (trimmed.startsWith('[')) {
            try {
                const parsed = JSON.parse(trimmed);
                return Array.isArray(parsed) ? parsed.filter(Boolean) : [];
            } catch (_) {
                return [trimmed];
            }
        }

        // Legacy Postgres array text format, e.g. {"https://...","https://..."}
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            const inner = trimmed.slice(1, -1);
            if (!inner) return [];
            return inner
                .split(',')
                .map((item) => item.replace(/^"|"$/g, '').trim())
                .filter(Boolean);
        }

        return [trimmed];
    }

    return [];
}

async function normalizeImagesForStorage(images) {
    const imageArray = toImageArray(images);
    if (imageArray.length === 0) return null;

    const columnType = await getImagesColumnType();
    if (columnType === '_text') {
        // Postgres text[] column: pass JS array directly.
        return imageArray;
    }

    // Postgres text/varchar column: persist JSON string for compatibility.
    return JSON.stringify(imageArray);
}

function deserializeImages(value) {
    return toImageArray(value);
}

function normalizeBlogRow(row) {
    if (!row) return row;
    return {
        ...row,
        images: deserializeImages(row.images),
    };
}

class blog {
    static async createBlog(blogData) {
        const query = 'INSERT INTO "Blog"("userid", "title", "content", "images", "video", "category_id", "createdat", "updatedat") VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW()) RETURNING *';
        const values = [
            blogData.userid,
            blogData.title,
            blogData.content,
            await normalizeImagesForStorage(blogData.images),
            blogData.video,
            blogData.category_id,
        ];
        try {
            const result = await pool.query(query, values);
            return normalizeBlogRow(result.rows[0]);
        } catch (error) {
            console.error('Error creating blog:', error);
            throw error;
        }
    }
    static async getBlog() {
        const query = `
            SELECT b.*, u.username as "authorName", c.name as "categoryName", c.icon_url as "categoryIcon"
            FROM "Blog" b 
            LEFT JOIN users u ON b.userid = u.uid
            LEFT JOIN blog_categories c ON b.category_id = c.id
        `;
        try {
            const result = await pool.query(query);
            return result.rows.map(normalizeBlogRow);
        } catch (error) {
            console.error('Error fetching Blog:', error);
            throw error;
        }
    }
    static async getBlogById(id) {
        const query = `
            SELECT b.*, u.username as "authorName", c.name as "categoryName", c.icon_url as "categoryIcon"
            FROM "Blog" b 
            LEFT JOIN users u ON b.userid = u.uid 
            LEFT JOIN blog_categories c ON b.category_id = c.id
            WHERE b.id = $1
        `;
        try {
            const result = await pool.query(query, [id]);
            return normalizeBlogRow(result.rows[0]);
        } catch (error) {
            console.error('Error fetching blog by ID:', error);
            throw error;
        }
    }
    static async updateBlog(id, blogData) {
        const existing = await this.getBlogById(id);
        if (!existing) {
            throw new Error('Blog not found');
        }

        const merged = {
            userid: blogData.userid ?? existing.userid,
            title: blogData.title ?? existing.title,
            content: blogData.content ?? existing.content,
            images: blogData.images ?? existing.images,
            video: blogData.video ?? existing.video,
            category_id: blogData.category_id ?? existing.category_id,
        };

        const query = 'UPDATE "Blog" SET "userid" = $1, "title" = $2, "content" = $3, "images" = $4, "video" = $5, "category_id" = $6, "updatedat" = NOW() WHERE "id" = $7 RETURNING *';
        const values = [
            merged.userid,
            merged.title,
            merged.content,
            await normalizeImagesForStorage(merged.images),
            merged.video,
            merged.category_id,
            id,
        ];
        try {
            const result = await pool.query(query, values);
            return normalizeBlogRow(result.rows[0]);
        } catch (error) {
            console.error('Error updating blog:', error);
            throw error;
        }
    }
    static async deleteBlog(id) {
        const query = 'DELETE FROM "Blog" WHERE "id" = $1 RETURNING *';
        try {
            const blogId = parseInt(id);
            if (isNaN(blogId)) {
                throw new Error('Invalid blog ID');
            }
            const result = await pool.query(query, [blogId]);
            if (result.rows.length === 0) {
                throw new Error('Blog not found');
            }
            return result.rows[0];
        } catch (error) {
            console.error('Error deleting blog:', error);
            throw error;
        }
    }
    static async getBlogAdmin() {
        const query = `
            SELECT b.*, u.username as "authorName", c.name as "categoryName", c.icon_url as "categoryIcon"
            FROM "Blog" b 
            LEFT JOIN users u ON b.userid = u.uid
            LEFT JOIN blog_categories c ON b.category_id = c.id
        `;
        try {
            const result = await pool.query(query);
            return result.rows.map(normalizeBlogRow);
        } catch (error) {
            console.error('Error fetching Blog:', error);
            throw error;
        }
    }

    static async getRandomBlogs(limit = 2) {
        const query = `
            SELECT b.*, u.username as "authorName", c.name as "categoryName", c.icon_url as "categoryIcon"
            FROM "Blog" b 
            LEFT JOIN users u ON b.userid = u.uid
            LEFT JOIN blog_categories c ON b.category_id = c.id
            ORDER BY RANDOM()
            LIMIT $1
        `;
        try {
            const result = await pool.query(query, [limit]);
            return result.rows.map(normalizeBlogRow);
        } catch (error) {
            console.error('Error fetching random blogs:', error);
            throw error;
        }
    }

    static async recordBlogView(blogId, userId) {
        // First, ensure the blog_views table exists (this is a bit hacky but safe for development)
        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS blog_views (
                id SERIAL PRIMARY KEY,
                blog_id INTEGER REFERENCES "Blog"(id) ON DELETE CASCADE,
                user_id INTEGER REFERENCES users(uid) ON DELETE CASCADE,
                viewed_at TIMESTAMP DEFAULT NOW(),
                UNIQUE(blog_id, user_id)
            )
        `;

        const updateViewsQuery = 'UPDATE "Blog" SET views = COALESCE(views, 0) + 1 WHERE id = $1';
        const recordViewQuery = 'INSERT INTO blog_views (blog_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING';

        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            await client.query(createTableQuery);
            await client.query(updateViewsQuery, [blogId]);
            if (userId) {
                await client.query(recordViewQuery, [blogId, userId]);
            }
            await client.query('COMMIT');
            return true;
        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Error recording blog view:', error);
            throw error;
        } finally {
            client.release();
        }
    }
}

module.exports = blog;