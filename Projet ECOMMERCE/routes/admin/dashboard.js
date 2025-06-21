const express = require('express');
const router = express.Router();
const dashboardController = require('../../controllers/dashboardController');
const { authenticateToken, isVendor } = require('../../middleware/auth');

// Toutes les routes nécessitent une authentification et le rôle vendeur
router.use(authenticateToken, isVendor);

// GET /api/admin/dashboard/sales
router.get('/sales', dashboardController.getSales);

// GET /api/admin/dashboard/top-products
router.get('/top-products', dashboardController.getTopProducts);

module.exports = router; 