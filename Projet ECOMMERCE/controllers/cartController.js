const { CartItem, Produit } = require('../models');

// GET /api/cart
exports.getCart = async (req, res) => {
    try {
        const cartItems = await CartItem.findAll({
            where: { UserId: req.user.id },
            include: [{
                model: Produit,
                attributes: ['id', 'nom', 'prix', 'quantite']
            }]
        });
        res.json({ items: cartItems });
    } catch (error) {
        console.error('Error in getCart:', error);
        res.status(500).json({ message: error.message });
    }
};

// POST /api/cart
exports.addToCart = async (req, res) => {
    try {
        const { productId, quantity, size, color } = req.body;
        
        // Vérifier si le produit existe
        const product = await Produit.findByPk(productId);
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }

        // Vérifier si l'item existe déjà dans le panier
        const existingItem = await CartItem.findOne({
            where: {
                UserId: req.user.id,
                ProductId: productId,
                size,
                color
            }
        });

        if (existingItem) {
            // Mettre à jour la quantité si l'item existe déjà
            existingItem.quantity += quantity;
            await existingItem.save();
            return res.status(200).json({ 
                message: 'Quantité mise à jour dans le panier',
                cartItemId: existingItem.id
            });
        }

        // Créer un nouvel item dans le panier
        const cartItem = await CartItem.create({
            UserId: req.user.id,
            ProductId: productId,
            quantity,
            size,
            color
        });

        res.status(201).json({ 
            message: 'Produit ajouté au panier',
            cartItemId: cartItem.id
        });
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

        const cartItem = await CartItem.findOne({
            where: {
                id: itemId,
                UserId: req.user.id
            }
        });

        if (!cartItem) {
            return res.status(404).json({ message: 'Item non trouvé dans le panier' });
        }

        await cartItem.update({
            quantity: quantity || cartItem.quantity,
            size: size || cartItem.size,
            color: color || cartItem.color
        });

        res.json({ message: 'Item du panier mis à jour' });
    } catch (error) {
        console.error('Error in updateCartItem:', error);
        res.status(500).json({ message: error.message });
    }
};

// DELETE /api/cart/:itemId
exports.removeFromCart = async (req, res) => {
    try {
        const { itemId } = req.params;

        const deleted = await CartItem.destroy({
            where: {
                id: itemId,
                UserId: req.user.id
            }
        });

        if (!deleted) {
            return res.status(404).json({ message: 'Item non trouvé dans le panier' });
        }

        res.json({ message: 'Item retiré du panier' });
    } catch (error) {
        console.error('Error in removeFromCart:', error);
        res.status(500).json({ message: error.message });
    }
}; 