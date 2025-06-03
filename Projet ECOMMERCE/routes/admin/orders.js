const express = require('express');
const router = express.Router();
const adminOrderController = require('../../controllers/adminOrderController');
const auth = require('../../middleware/auth');
const isVendor = require('../../middleware/isVendor');

// Toutes les routes nécessitent une authentification et le rôle vendeur
router.use(auth);
router.use(isVendor);

// GET /api/admin/orders
router.get('/', adminOrderController.getAllOrders);

// GET /api/admin/orders/:id
router.get('/:id', adminOrderController.getOrderById);

// PUT /api/admin/orders/:id/status
router.put('/:id/status', adminOrderController.updateOrderStatus);

module.exports = router; 