const orderService = require('../services/orderService');

// GET /api/orders
exports.getOrders = async (req, res) => {
    try {
        const orders = await orderService.getOrders(req.user.id);
        console.log('RETOUR API /api/orders :', JSON.stringify(orders, null, 2));
        res.json(orders);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/orders/:id
exports.getOrderById = async (req, res) => {
    try {
        const order = await orderService.getOrderById(req.params.id, req.user.id);
        res.json(order);
    } catch (error) {
        res.status(404).json({ message: 'Commande non trouvée' });
    }
};

// POST /api/orders
exports.createOrder = async (req, res) => {
    console.log('POST /api/orders appelé, body:', req.body);
    try {
        const { items, adresse_livraison, methode_paiement } = req.body;

        const order = await orderService.createOrder(req.user.id, {
            items,
            adresse_livraison,
            methode_paiement
        });

        res.status(201).json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/orders/:id/cancel
exports.cancelOrder = async (req, res) => {
    console.log('🚫 POST /api/orders/:id/cancel appelé');
    console.log('   - Order ID:', req.params.id);
    console.log('   - User ID:', req.user.id);
    
    try {
        const order = await orderService.cancelOrder(req.params.id, req.user.id);
        console.log('✅ Commande annulée avec succès:', order.id);
        res.json(order);
    } catch (error) {
        console.error('❌ Erreur lors de l\'annulation:', error.message);
        res.status(500).json({ message: error.message });
    }
}; 