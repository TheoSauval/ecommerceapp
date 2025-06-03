const { Notification, User } = require('../models');

// GET /api/notifications
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.findAll({
            where: { user_id: req.user.id },
            order: [['createdAt', 'DESC']]
        });
        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/notifications/register-device
exports.registerDevice = async (req, res) => {
    try {
        const { token } = req.body;
        const user = await User.findByPk(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
        if (user.device_token === token) {
            return res.status(400).json({ message: 'Token déjà enregistré' });
        }
        await user.update({ device_token: token });
        res.status(201).json({ message: 'Token enregistré avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/notifications/:id
exports.deleteNotification = async (req, res) => {
    try {
        const notification = await Notification.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id
            }
        });
        if (!notification) {
            return res.status(404).json({ message: 'Notification non trouvée' });
        }
        await notification.destroy();
        res.json({ message: 'Notification supprimée avec succès' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 