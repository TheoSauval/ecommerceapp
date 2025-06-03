const { Commande, Produit, User } = require('../models');
const { Op } = require('sequelize');

// GET /api/orders
exports.getOrders = async (req, res) => {
    try {
        const orders = await Commande.findAll({
            where: { user_id: req.user.id },
            include: [
                { model: Produit },
                { model: User, attributes: ['id', 'mail', 'nom', 'prenom'] }
            ],
            order: [['createdAt', 'DESC']]
        });
        res.json(orders);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/orders/:id
exports.getOrderById = async (req, res) => {
    try {
        const order = await Commande.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id
            },
            include: [
                { model: Produit },
                { model: User, attributes: ['id', 'mail', 'nom', 'prenom'] }
            ]
        });
        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/orders
exports.createOrder = async (req, res) => {
    try {
        const { items, adresse_livraison, methode_paiement } = req.body;

        // Vérifier que tous les produits existent et sont en stock
        const productIds = items.map(item => item.productId);
        const products = await Produit.findAll({
            where: {
                id: {
                    [Op.in]: productIds
                }
            }
        });

        if (products.length !== productIds.length) {
            return res.status(400).json({ message: 'Un ou plusieurs produits n\'existent pas' });
        }

        for (const product of products) {
            const item = items.find(i => i.productId === product.id);
            if (product.quantite < item.quantity) {
                return res.status(400).json({ message: `Stock insuffisant pour ${product.nom}` });
            }
        }

        // Créer la commande
        const order = await Commande.create({
            user_id: req.user.id,
            status: 'En attente',
            adresse_livraison,
            methode_paiement,
            prix_total: products.reduce((sum, product) => {
                const item = items.find(i => i.productId === product.id);
                return sum + product.prix * item.quantity;
            }, 0)
        });

        // Ajouter les produits à la commande
        await order.addProduits(products.map(product => {
            const item = items.find(i => i.productId === product.id);
            return {
                id: product.id,
                through: { quantite: item.quantity }
            };
        }));

        // Mettre à jour le stock
        for (const product of products) {
            const item = items.find(i => i.productId === product.id);
            await product.update({
                quantite: product.quantite - item.quantity
            });
        }

        res.status(201).json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/orders/:id/cancel
exports.cancelOrder = async (req, res) => {
    try {
        const order = await Commande.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id
            }
        });
        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        if (order.status !== 'En attente') {
            return res.status(400).json({ message: 'Impossible d\'annuler une commande déjà traitée' });
        }
        await order.update({ status: 'Annulée' });
        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 