const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { Commande, Produit } = require('../models');
const sequelize = require('sequelize');

// Middleware pour vérifier le rôle admin
router.use(auth.isAdmin);

// GET /api/admin/dashboard/sales
router.get('/dashboard/sales', async (req, res) => {
  try {
    const orders = await Commande.findAll({
      where: {
        status: ['En attente', 'Expédiée', 'Livrée']
      }
    });

    const totalRevenue = orders.reduce((sum, order) => sum + parseFloat(order.prix_total), 0);

    // Calculer les ventes par jour
    const salesByDay = {};
    orders.forEach(order => {
      const date = order.createdAt.toISOString().split('T')[0];
      salesByDay[date] = (salesByDay[date] || 0) + parseFloat(order.prix_total);
    });

    // Calculer les ventes par mois
    const salesByMonth = {};
    orders.forEach(order => {
      const month = order.createdAt.toISOString().slice(0, 7); // Format: YYYY-MM
      salesByMonth[month] = (salesByMonth[month] || 0) + parseFloat(order.prix_total);
    });

    res.json({
      totalRevenue,
      salesByDay,
      salesByMonth
    });
  } catch (error) {
    console.error('Error in getSales:', error);
    res.status(500).json({ message: error.message });
  }
});

// GET /api/admin/dashboard/top-products
router.get('/dashboard/top-products', async (req, res) => {
  try {
    const topProducts = await Produit.findAll({
      attributes: [
        'id',
        'nom',
        'prix',
        [sequelize.fn('COUNT', sequelize.col('orders_products.productId')), 'totalSales'],
        [sequelize.fn('SUM', sequelize.col('orders_products.quantity')), 'totalQuantity']
      ],
      include: [{
        model: Commande,
        through: { attributes: ['quantity'] },
        attributes: []
      }],
      group: ['Produit.id'],
      order: [[sequelize.literal('totalQuantity'), 'DESC']],
      limit: 10
    });

    const formattedProducts = topProducts.map(product => ({
      id: product.id,
      name: product.nom,
      price: product.prix,
      totalSales: parseInt(product.getDataValue('totalSales')),
      revenue: parseFloat(product.prix) * parseInt(product.getDataValue('totalQuantity'))
    }));

    res.json(formattedProducts);
  } catch (error) {
    console.error('Error in getTopProducts:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 