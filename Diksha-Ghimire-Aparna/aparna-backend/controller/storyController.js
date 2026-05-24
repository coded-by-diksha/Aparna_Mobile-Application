const Stories = require('../model/Stories');
const NotificationHelper = require('../utils/notificationHelper');

class StoryController {
    static async getAllStories(req, res) {
        try {
            const stories = await Stories.getAllStories();
            res.status(200).json(stories);
        } catch (error) {
            console.error('Error fetching stories:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async createStory(req, res) {
        const { title, content, is_anonymous, author_name } = req.body;
        const user_id = req.user ? req.user.uid : null;

        try {
            const storyData = {
                user_id,
                title,
                content,
                is_anonymous,
                author_name: is_anonymous ? 'Anonymous' : author_name
            };
            const newStory = await Stories.createStory(storyData);

            // Send notification to all users about the new story
            const displayAuthor = is_anonymous ? 'Anonymous' : (author_name || 'A user');
            NotificationHelper.notifyNewStory(title, newStory.id, displayAuthor)
                .then(result => {
                    console.log(`✅ Story notification sent: ${result.successCount} successful, ${result.failureCount} failed`);
                })
                .catch(error => {
                    console.error('❌ Error sending story notification:', error);
                });

            res.status(201).json(newStory);
        } catch (error) {
            console.error('Error creating story:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }

    static async deleteStory(req, res) {
        const { id } = req.params;
        const uid = req.user.uid;
        try {
            const success = await Stories.deleteStory(id, uid);
            if (!success) {
                return res.status(404).json({ error: 'Story not found' });
            }
            res.status(200).json({ message: 'Story deleted successfully' });
        } catch (error) {
            console.error('Error deleting story:', error);
            res.status(500).json({ error: 'Internal server error' });
        }
    }
}

// Ensure database table exists

module.exports = StoryController;
