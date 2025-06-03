const express = require('express');
const router = express.Router();
const adminProductController = require('../../controllers/adminProductController');
const auth = require('../../middleware/auth');
const isVendor = require('../../middleware/isVendor');

// Toutes les routes nécessitent une authentification et le rôle vendeur
router.use(auth);
router.use(isVendor);

// GET /api/admin/products
router.get('/', adminProductController.getAllProducts);

// GET /api/admin/products/:id
router.get('/:id', adminProductController.getProductById);

// POST /api/admin/products
router.post('/', adminProductController.createProduct);

// PUT /api/admin/products/:id
router.put('/:id', adminProductController.updateProduct);

// DELETE /api/admin/products/:id
router.delete('/:id', adminProductController.deleteProduct);

// POST /api/admin/products/:id/heights
router.post('/:id/heights', adminProductController.addHeight);

// DELETE /api/admin/products/:id/heights/:hid
router.delete('/:id/heights/:hid', adminProductController.removeHeight);

// POST /api/admin/products/:id/colors
router.post('/:id/colors', adminProductController.addColor);

// DELETE /api/admin/products/:id/colors/:cid
router.delete('/:id/colors/:cid', adminProductController.removeColor);

module.exports = router; 