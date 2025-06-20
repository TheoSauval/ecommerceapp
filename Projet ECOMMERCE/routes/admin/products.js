const express = require('express');
const router = express.Router();
const adminProductController = require('../../controllers/adminProductController');
const { authenticateToken, isVendor } = require('../../middleware/auth');

// Toutes les routes nécessitent une authentification et le rôle vendeur
router.use(authenticateToken, isVendor);

// GET /api/admin/products
router.get('/', adminProductController.getAllProducts);

// GET /api/admin/products/colors
router.get('/colors', adminProductController.getAllColors);

// GET /api/admin/products/heights
router.get('/heights', adminProductController.getAllHeights);

// GET /api/admin/products/:id
router.get('/:id', adminProductController.getProductById);

// POST /api/admin/products
router.post('/', adminProductController.createProduct);

// PUT /api/admin/products/:id
router.put('/:id', adminProductController.updateProduct);

// DELETE /api/admin/products/:id
router.delete('/:id', adminProductController.deleteProduct);

// POST /api/admin/products/:id/variants
router.post('/:id/variants', adminProductController.addVariant);

// DELETE /api/admin/products/:id/variants/:variantId
router.delete('/:id/variants/:variantId', adminProductController.removeVariant);

module.exports = router; 