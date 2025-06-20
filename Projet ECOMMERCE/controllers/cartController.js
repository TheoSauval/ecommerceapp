const cartService = require('../services/cartService');

// GET /api/cart
exports.getCart = async (req, res) => {
    try {
        const result = await cartService.getCart(req.user.id);
        res.json(result);
    } catch (error) {
        console.error('Error in getCart:', error);
        res.status(500).json({ message: error.message });
    }
};

// POST /api/cart
exports.addToCart = async (req, res) => {
    try {
        const { productId, quantity, size, color } = req.body;
        
        const result = await cartService.addToCart(req.user.id, productId, quantity, size, color);
        res.status(201).json(result);
    } catch (error) {
        console.error('Error in addToCart:', error);
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/cart/:itemId
exports.updateCartItem = async (req, res) => {
    try {
        const { itemId } = req.params;
        const { quantity, size, color } = req.body;

        const updates = {};
        if (quantity !== undefined) updates.quantity = quantity;
        if (size !== undefined) updates.size = size;
        if (color !== undefined) updates.color = color;

        const cartItem = await cartService.updateCartItem(itemId, req.user.id, updates);
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

        await cartService.removeFromCart(itemId, req.user.id);
        res.json({ message: 'Item retiré du panier' });
    } catch (error) {
        console.error('Error in removeFromCart:', error);
        res.status(500).json({ message: error.message });
    }
}; 