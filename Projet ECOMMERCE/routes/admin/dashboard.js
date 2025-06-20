const express = require('express');
const router = express.Router();
const dashboardController = require('../../controllers/dashboardController');
const { authenticateToken, isAdmin } = require('../../middleware/auth');

// Toutes les routes nécessitent une authentification et le rôle admin
router.use(authenticateToken, isAdmin);

// GET /api/admin/dashboard/sales
router.get('/sales', dashboardController.getSales);

// GET /api/admin/dashboard/top-products
router.get('/top-products', dashboardController.getTopProducts);

module.exports = router; 