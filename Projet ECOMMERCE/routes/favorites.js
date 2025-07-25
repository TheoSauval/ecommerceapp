const express = require('express');
const router = express.Router();
const favoriteController = require('../controllers/favoriteController');
const { authenticateToken } = require('../middleware/auth');

// Toutes les routes nécessitent une authentification
router.use(authenticateToken);

// GET /api/users/me/favorites
router.get('/', favoriteController.getFavorites);

// POST /api/users/me/favorites
router.post('/', favoriteController.addFavorite);

// DELETE /api/users/me/favorites/:id
router.delete('/:id', favoriteController.removeFavorite);

module.exports = router; 