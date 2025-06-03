const { User, Produit } = require('../models');

// GET /api/users/me/favorites
exports.getFavorites = async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id, {
            include: [{ model: Produit, as: 'Favorites' }]
        });
        res.json(user ? user.Favorites : []);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/users/me/favorites
exports.addFavorite = async (req, res) => {
    try {
        const { productId } = req.body;
        const product = await Produit.findByPk(productId);
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        const user = await User.findByPk(req.user.id);
        const favorites = await user.getFavorites({ where: { id: productId } });
        if (favorites.length > 0) {
            return res.status(400).json({ message: 'Produit déjà dans les favoris' });
        }
        await user.addFavorite(product);
        res.status(201).json({ message: 'Produit ajouté aux favoris' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/users/me/favorites/:id
exports.removeFavorite = async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id);
        const product = await Produit.findByPk(req.params.id);
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        const favorites = await user.getFavorites({ where: { id: req.params.id } });
        if (favorites.length === 0) {
            return res.status(404).json({ message: 'Produit non trouvé dans les favoris' });
        }
        await user.removeFavorite(product);
        res.json({ message: 'Produit retiré des favoris' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 