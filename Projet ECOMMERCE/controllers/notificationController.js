const notificationService = require('../services/notificationService');

// GET /api/notifications
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await notificationService.getNotifications(req.user.id);
        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/notifications
exports.createNotification = async (req, res) => {
    try {
        const { status } = req.body;
        const notification = await notificationService.createNotification(req.user.id, status);
        res.status(201).json(notification);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/notifications/:id
exports.updateNotification = async (req, res) => {
    try {
        const notification = await notificationService.updateNotification(req.params.id, req.body);
        res.json(notification);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/notifications/:id
exports.deleteNotification = async (req, res) => {
    try {
        await notificationService.deleteNotification(req.params.id, req.user.id);
        res.json({ message: 'Notification supprimée' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
    try {
        const notification = await notificationService.markAsRead(req.params.id, req.user.id);
        res.json(notification);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/notifications/read-all
exports.markAllAsRead = async (req, res) => {
    try {
        await notificationService.markAllAsRead(req.user.id);
        res.json({ message: 'Toutes les notifications marquées comme lues' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/notifications/unread-count
exports.getUnreadCount = async (req, res) => {
    try {
        const count = await notificationService.getUnreadCount(req.user.id);
        res.json({ count });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/notifications/clear-all
exports.clearAllNotifications = async (req, res) => {
    try {
        await notificationService.clearAllNotifications(req.user.id);
        res.json({ message: 'Toutes les notifications supprimées' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 