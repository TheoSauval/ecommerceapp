const express = require('express');
const router = express.Router();
const { authenticateToken, isAdmin } = require('../middleware/auth');
const dashboardController = require('../controllers/dashboardController');

// Toutes les routes nécessitent une authentification et le rôle admin
router.use(authenticateToken, isAdmin);

// GET /api/admin/dashboard/sales
router.get('/dashboard/sales', dashboardController.getSales);

// GET /api/admin/dashboard/top-products
router.get('/dashboard/top-products', dashboardController.getTopProducts);

module.exports = router; 