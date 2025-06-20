const orderService = require('../services/orderService');
const productService = require('../services/productService');
const userService = require('../services/userService');

// GET /api/admin/orders
exports.getAllOrders = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        
        const products = await productService.getProductsByVendor(vendor.id);
        const productIds = products.map(p => p.id);
        
        const orders = await orderService.getOrdersByProducts(productIds);
        res.json(orders);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/orders/:id
exports.getOrderById = async (req, res) => {
    try {
        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        
        const products = await productService.getProductsByVendor(vendor.id);
        const productIds = products.map(p => p.id);
        
        const order = await orderService.getOrderById(req.params.id);
        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        
        // Vérifier que la commande contient des produits du vendeur
        const orderProductIds = order.items?.map(item => item.produit_id) || [];
        const hasVendorProducts = orderProductIds.some(id => productIds.includes(id));
        
        if (!hasVendorProducts) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        
        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/admin/orders/:id/status
exports.updateOrderStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const validStatuses = ['En attente', 'Expédiée', 'Livrée', 'Annulée'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Statut invalide' });
        }

        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        
        const products = await productService.getProductsByVendor(vendor.id);
        const productIds = products.map(p => p.id);
        
        const order = await orderService.getOrderById(req.params.id);
        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        
        // Vérifier que la commande contient des produits du vendeur
        const orderProductIds = order.items?.map(item => item.produit_id) || [];
        const hasVendorProducts = orderProductIds.some(id => productIds.includes(id));
        
        if (!hasVendorProducts) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        // Vérifier si le changement de statut est valide
        if (order.status === 'Annulée' && status !== 'Annulée') {
            return res.status(400).json({ message: 'Impossible de modifier une commande annulée' });
        }

        if (order.status === 'Livrée' && status !== 'Livrée') {
            return res.status(400).json({ message: 'Impossible de modifier une commande livrée' });
        }

        const updatedOrder = await orderService.updateOrderStatus(req.params.id, status);
        res.json(updatedOrder);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 