const User = require('../models/users');
const Product = require('../models/products');

// GET /api/users/me/favorites
exports.getFavorites = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).populate('favorites');
        res.json(user.favorites);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/users/me/favorites
exports.addFavorite = async (req, res) => {
    try {
        const { productId } = req.body;
        
        // Vérifier si le produit existe
        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }

        const user = await User.findById(req.user.id);
        
        // Vérifier si le produit est déjà dans les favoris
        if (user.favorites.includes(productId)) {
            return res.status(400).json({ message: 'Produit déjà dans les favoris' });
        }

        user.favorites.push(productId);
        await user.save();

        res.status(201).json({ message: 'Produit ajouté aux favoris' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/users/me/favorites/:id
exports.removeFavorite = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        
        // Vérifier si le produit est dans les favoris
        if (!user.favorites.includes(req.params.id)) {
            return res.status(404).json({ message: 'Produit non trouvé dans les favoris' });
        }

        user.favorites = user.favorites.filter(id => id.toString() !== req.params.id);
        await user.save();

        res.json({ message: 'Produit retiré des favoris' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 