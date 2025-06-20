const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const notificationController = require('../controllers/notificationController');

// Toutes les routes nécessitent une authentification
router.use(authenticateToken);

// GET /api/notifications
router.get('/', notificationController.getNotifications);

// POST /api/notifications
router.post('/', notificationController.createNotification);

// PUT /api/notifications/:id
router.put('/:id', notificationController.updateNotification);

// DELETE /api/notifications/:id
router.delete('/:id', notificationController.deleteNotification);

// PUT /api/notifications/:id/read
router.put('/:id/read', notificationController.markAsRead);

// PUT /api/notifications/read-all
router.put('/read-all', notificationController.markAllAsRead);

// GET /api/notifications/unread-count
router.get('/unread-count', notificationController.getUnreadCount);

// DELETE /api/notifications/clear-all
router.delete('/clear-all', notificationController.clearAllNotifications);

module.exports = router; 