const { Produit, Commande } = require('../models');
const { Op } = require('sequelize');

// GET /api/admin/dashboard/sales
exports.getSales = async (req, res) => {
    try {
        const orders = await Commande.findAll({
            where: {
                status: {
                    [Op.notIn]: ['Annulée', 'En attente']
                }
            },
            include: [{
                model: Produit
            }]
        });

        const totalRevenue = orders.reduce((sum, order) => {
            return sum + order.Produits.reduce((orderSum, p) => orderSum + p.prix * p.CommandeProduit.quantite, 0);
        }, 0);

        const salesByDay = {};
        const salesByMonth = {};

        orders.forEach(order => {
            const date = new Date(order.createdAt);
            const day = date.toISOString().split('T')[0];
            const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

            const orderTotal = order.Produits.reduce((sum, p) => sum + p.prix * p.CommandeProduit.quantite, 0);

            salesByDay[day] = (salesByDay[day] || 0) + orderTotal;
            salesByMonth[month] = (salesByMonth[month] || 0) + orderTotal;
        });

        res.json({
            totalRevenue,
            salesByDay,
            salesByMonth
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/dashboard/top-products
exports.getTopProducts = async (req, res) => {
    try {
        const orders = await Commande.findAll({
            where: {
                status: {
                    [Op.notIn]: ['Annulée', 'En attente']
                }
            },
            include: [{
                model: Produit
            }]
        });

        const salesPerProduct = {};

        orders.forEach(order => {
            order.Produits.forEach(p => {
                if (!salesPerProduct[p.id]) {
                    salesPerProduct[p.id] = {
                        id: p.id,
                        name: p.nom,
                        price: p.prix,
                        totalSales: 0,
                        revenue: 0
                    };
                }
                salesPerProduct[p.id].revenue += p.prix * p.CommandeProduit.quantite;
                salesPerProduct[p.id].totalSales += p.CommandeProduit.quantite;
            });
        });

        const topProducts = Object.values(salesPerProduct)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 10);

        res.json(topProducts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 