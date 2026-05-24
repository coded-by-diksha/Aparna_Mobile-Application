const User = require('../model/User');
const blog = require('../model/blogs');
const ExpertHelp = require('../model/experthelp');
const bcrypt = require('bcrypt');

const adminController = {
    async createUserByAdmin(req, res) {
        try {
            if (req.user?.role !== 'admin') {
                return res.status(403).json({ error: 'Only admin can create users' });
            }

            const {
                username,
                email,
                phone = null,
                dateofbirth = null,
                password,
                role = 'user',
            } = req.body;

            if (!username || !email || !password) {
                return res.status(400).json({
                    error: 'username, email and password are required',
                });
            }

            const normalizedRole = String(role).toLowerCase();
            if (!['user', 'admin'].includes(normalizedRole)) {
                return res.status(400).json({ error: 'role must be either user or admin' });
            }

            const existingEmail = await User.getUserByEmail(email);
            if (existingEmail) {
                return res.status(409).json({ error: 'Email is already registered' });
            }

            const existingUsername = await User.getUserByUsername(username);
            if (existingUsername) {
                return res.status(409).json({ error: 'Username is already taken' });
            }

            const hashedPassword = await bcrypt.hash(password, 12);
            const newUser = await User.createUser({
                username,
                email,
                phone,
                dateofbirth,
                password: hashedPassword,
                role: normalizedRole,
                emailVerified: true,
            });

            return res.status(201).json({
                message: 'User created successfully',
                user: {
                    uid: newUser.uid,
                    username: newUser.username,
                    email: newUser.email,
                    phone: newUser.phone,
                    dateofbirth: newUser.dateofbirth,
                    role: newUser.role,
                    createdat: newUser.createdat,
                },
            });
        } catch (error) {
            console.error('Error creating user by admin:', error);
            if (error.code === '23505') {
                const constraint = String(error.constraint || '');
                if (constraint.includes('users_email')) {
                    return res.status(409).json({ error: 'Email is already registered' });
                }
                if (constraint.includes('users_username')) {
                    return res.status(409).json({ error: 'Username is already taken' });
                }
                if (constraint.includes('users_phone')) {
                    return res.status(409).json({ error: 'Phone is already registered' });
                }
            }
            return res.status(500).json({ error: 'Internal server error' });
        }
    },

    async getAllUsers(req, res) {
        try {
            const users = await User.getAllUsers();
            res.status(200).json(users);
        } catch (error) {
            console.error('Error fetching users:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    },
   
    async deleteBlogByID(req, res) {
        try {
            const { id } = req.params;
            const result = await blog.deleteBlog(id);
            if (result) {
                res.status(200).json({ message: 'Blog deleted successfully' });
            } else {
                res.status(404).json({ message: 'Blog not found' });
            }
        } catch (error) {
            console.error('Error deleting blog:', error);
            res.status(500).json({ error: 'Internal server error', message: error.message });
        }
    },
    
    async deleteUserByID(req, res) {
        try {
            const { id } = req.params;
            const result = await User.deleteUser(id);
            if (result) {
                res.status(200).json({ message: 'User deleted successfully' });
            } else {
                res.status(404).json({ message: 'User not found' });
            }
        } catch (error) {
            console.error('Error deleting user:', error);
            res.status(500).json({ error: 'Internal server error', message: error.message });
        }
    },
    async getStats(req, res) {
        console.log('GET /admin/stats request received');
        try {
            const userCount = await User.countUsers();
            const blogs = await blog.getBlog();
            const blogCount = blogs.length;
            const expertCount = await ExpertHelp.countExperts();

            res.status(200).json({
                userCount: parseInt(userCount),
                blogCount: blogCount,
                clinicCount: parseInt(expertCount),
                activeToday: 423 // Mocked for now
            });
        } catch (error) {
            console.error('Error fetching stats:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

}

module.exports = adminController;
