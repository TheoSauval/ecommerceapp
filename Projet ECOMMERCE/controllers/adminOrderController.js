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
        
        const order = await orderService.getOrderByIdAdmin(req.params.id);
        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        
        // Vérifier que la commande contient des produits du vendeur
        const orderProductIds = order.order_variants?.map(variant => {
            const productId = variant.product_variant?.products?.id;
            console.log('🔍 Variant:', variant.variant_id, 'Product ID:', productId);
            return productId;
        }).filter(id => id !== undefined) || [];
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
        console.log('🔄 Mise à jour du statut de commande:', req.params.id, 'Nouveau statut:', req.body.status);
        
        const { status } = req.body;
        const validStatuses = ['En attente', 'Payé', 'Expédiée', 'Livrée', 'Annulée'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Statut invalide' });
        }

        const vendor = await userService.getVendorProfile(req.user.id);
        if (!vendor) {
            console.log('❌ Vendeur non trouvé pour user_id:', req.user.id);
            return res.status(404).json({ message: 'Vendeur non trouvé' });
        }
        
        console.log('✅ Vendeur trouvé:', vendor.id);
        
        const products = await productService.getProductsByVendor(vendor.id);
        const productIds = products.map(p => p.id);
        console.log('📦 Produits du vendeur:', productIds);
        
        const order = await orderService.getOrderByIdAdmin(req.params.id);
        if (!order) {
            console.log('❌ Commande non trouvée:', req.params.id);
            return res.status(404).json({ message: 'Commande non trouvée' });
        }
        
        console.log('✅ Commande trouvée:', order.id, 'Statut actuel:', order.status);
        console.log('📋 Structure de la commande:', JSON.stringify(order.order_variants, null, 2));
        
        // Vérifier que la commande contient des produits du vendeur
        const orderProductIds = order.order_variants?.map(variant => {
            const productId = variant.product_variant?.products?.id;
            console.log('🔍 Variant:', variant.variant_id, 'Product ID:', productId);
            return productId;
        }).filter(id => id !== undefined) || [];
        const hasVendorProducts = orderProductIds.some(id => productIds.includes(id));
        
        console.log('📋 Produits de la commande:', orderProductIds);
        console.log('🔍 Commande contient des produits du vendeur:', hasVendorProducts);
        
        if (!hasVendorProducts) {
            console.log('❌ Commande ne contient pas de produits du vendeur');
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        // Vérifier si le changement de statut est valide
        if (order.status === 'Annulée') {
            console.log('❌ Impossible de modifier une commande annulée');
            return res.status(400).json({ message: 'Impossible de modifier une commande annulée' });
        }

        if (order.status === 'Livrée') {
            console.log('❌ Impossible de modifier une commande livrée');
            return res.status(400).json({ message: 'Impossible de modifier une commande livrée' });
        }

        // Vérifier la progression logique des statuts
        const statusOrder = ['En attente', 'Payé', 'Expédiée', 'Livrée'];
        const currentIndex = statusOrder.indexOf(order.status);
        const newIndex = statusOrder.indexOf(status);
        
        if (newIndex < currentIndex) {
            console.log('❌ Tentative de retour en arrière dans le cycle de statut');
            return res.status(400).json({ 
                message: 'Impossible de revenir à un statut précédent. Le cycle de statut est : En attente → Payé → Expédiée → Livrée' 
            });
        }

        console.log('✅ Validation OK, mise à jour du statut...');
        const updatedOrder = await orderService.updateOrderStatus(req.params.id, status);
        console.log('✅ Statut mis à jour avec succès:', updatedOrder);
        res.json(updatedOrder);
    } catch (error) {
        console.error('❌ Erreur lors de la mise à jour du statut:', error);
        res.status(500).json({ message: error.message });
    }
}; 