const { Commande, Produit, User } = require('../models');
const { Op } = require('sequelize');

// GET /api/admin/orders
exports.getAllOrders = async (req, res) => {
    try {
        const products = await Produit.findAll({
            where: { vendeur_id: req.user.id }
        });
        const productIds = products.map(p => p.id);

        const orders = await Commande.findAll({
            include: [{
                model: Produit,
                where: {
                    id: {
                        [Op.in]: productIds
                    }
                }
            }, {
                model: User,
                attributes: ['id', 'mail', 'nom', 'prenom']
            }],
            order: [['createdAt', 'DESC']]
        });

        res.json(orders);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/orders/:id
exports.getOrderById = async (req, res) => {
    try {
        const products = await Produit.findAll({
            where: { vendeur_id: req.user.id }
        });
        const productIds = products.map(p => p.id);

        const order = await Commande.findOne({
            where: { id: req.params.id },
            include: [{
                model: Produit,
                where: {
                    id: {
                        [Op.in]: productIds
                    }
                }
            }, {
                model: User,
                attributes: ['id', 'mail', 'nom', 'prenom']
            }]
        });

        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/admin/orders/:id/status
exports.updateOrderStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const validStatuses = ['En attente', 'Expédiée', 'Livrée', 'Annulée'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Statut invalide' });
        }

        const products = await Produit.findAll({
            where: { vendeur_id: req.user.id }
        });
        const productIds = products.map(p => p.id);

        const order = await Commande.findOne({
            where: { id: req.params.id },
            include: [{
                model: Produit,
                where: {
                    id: {
                        [Op.in]: productIds
                    }
                }
            }]
        });

        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        // Vérifier si le changement de statut est valide
        if (order.status === 'Annulée' && status !== 'Annulée') {
            return res.status(400).json({ message: 'Impossible de modifier une commande annulée' });
        }

        if (order.status === 'Livrée' && status !== 'Livrée') {
            return res.status(400).json({ message: 'Impossible de modifier une commande livrée' });
        }

        await order.update({ status });
        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 