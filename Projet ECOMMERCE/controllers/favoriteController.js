const favoriteService = require('../services/favoriteService');

// GET /api/users/me/favorites
exports.getFavorites = async (req, res) => {
    try {
        const favorites = await favoriteService.getFavorites(req.user.id);
        res.json(favorites);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/users/me/favorites
exports.addFavorite = async (req, res) => {
    try {
        const { product_id } = req.body;
        if (!product_id) {
            return res.status(400).json({ message: "Le corps de la requête doit contenir 'product_id'." });
        }
        const result = await favoriteService.addFavorite(req.user.id, product_id);
        res.status(201).json(result);
    } catch (error) {
        res.status(error.message.includes("non trouvé") ? 404 : 500).json({ message: error.message });
    }
};

// DELETE /api/users/me/favorites/:id
exports.removeFavorite = async (req, res) => {
    try {
        const result = await favoriteService.removeFavorite(req.user.id, req.params.id);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 