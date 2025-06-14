const { User } = require('../models');

module.exports = async (req, res, next) => {
    try {
        console.log('User reçu dans isVendor:', req.user ? req.user.toJSON() : null);
        const user = await User.findByPk(req.user.id);
        
        if (!user || user.role !== 'vendor') {
            return res.status(403).json({ message: 'Accès refusé. Rôle vendeur requis.' });
        }
        
        next();
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};