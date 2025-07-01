const cartService = require('../services/cartService');

// GET /api/cart
exports.getCart = async (req, res) => {
    try {
        const items = await cartService.getCart(req.user.id);
        res.json(items);
    } catch (error) {
        console.error('Error in getCart:', error);
        res.status(500).json({ message: error.message });
    }
};

// POST /api/cart
exports.addToCart = async (req, res) => {
    try {
        const { variantId, quantity } = req.body;
        const result = await cartService.addToCart(req.user.id, variantId, quantity);
        res.status(201).json(result);
    } catch (error) {
        console.error('Error in addToCart:', error);
        res.status(400).json({ message: error.message });
    }
};

// PUT /api/cart/:itemId
exports.updateCartItem = async (req, res) => {
    try {
        const { itemId } = req.params;
        const { quantity } = req.body;

        if (typeof quantity !== 'number') {
            return res.status(400).json({ message: 'La quantité doit être un nombre.' });
        }

        const cartItem = await cartService.updateCartItem(itemId, req.user.id, quantity);
        res.json({ message: 'Item du panier mis à jour', cartItem });
    } catch (error) {
        console.error('Error in updateCartItem:', error);
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/cart/:itemId
exports.removeFromCart = async (req, res) => {
    try {
        const { itemId } = req.params;
        const result = await cartService.removeFromCart(itemId, req.user.id);
        res.json(result);
    } catch (error) {
        console.error('Error in removeFromCart:', error);
        res.status(500).json({ message: error.message });
    }
}; 

// DELETE /api/cart/clear
exports.clearCart = async (req, res) => {
    try {
        const result = await cartService.clearCart(req.user.id);
        res.json(result);
    } catch (error) {
        console.error('Error in clearCart:', error);
        res.status(500).json({ message: error.message });
    }
}; 