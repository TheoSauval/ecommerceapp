const orderService = require('../services/orderService');
const productService = require('../services/productService');

// GET /api/admin/dashboard/sales
exports.getSales = async (req, res) => {
    try {
        // Récupérer l'ID du vendeur connecté
        const vendorId = await getVendorId(req.user.id);
        if (!vendorId) {
            return res.status(403).json({ message: 'Vendeur non trouvé' });
        }

        const orders = await orderService.getOrdersByVendor(vendorId);
        
        // Filtrer seulement les commandes complétées
        const completedOrders = orders.filter(order => 
            ['Expédiée', 'Livrée'].includes(order.status)
        );
        
        const totalRevenue = completedOrders.reduce((sum, order) => {
            return sum + (order.order_variants?.reduce((orderSum, item) => 
                orderSum + (item.unit_price * item.quantity), 0) || 0);
        }, 0);

        const salesByDay = {};
        const salesByMonth = {};

        completedOrders.forEach(order => {
            const date = new Date(order.created_at);
            const day = date.toISOString().split('T')[0];
            const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

            const orderTotal = order.order_variants?.reduce((sum, item) => 
                sum + (item.unit_price * item.quantity), 0) || 0;

            salesByDay[day] = (salesByDay[day] || 0) + orderTotal;
            salesByMonth[month] = (salesByMonth[month] || 0) + orderTotal;
        });

        res.json({
            totalRevenue,
            salesByDay,
            salesByMonth
        });
    } catch (error) {
        console.error('Erreur dashboard sales:', error);
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/dashboard/top-products
exports.getTopProducts = async (req, res) => {
    try {
        // Récupérer l'ID du vendeur connecté
        const vendorId = await getVendorId(req.user.id);
        if (!vendorId) {
            return res.status(403).json({ message: 'Vendeur non trouvé' });
        }

        const orders = await orderService.getOrdersByVendor(vendorId);
        
        // Filtrer seulement les commandes complétées
        const completedOrders = orders.filter(order => 
            ['Expédiée', 'Livrée'].includes(order.status)
        );
        
        const salesPerProduct = {};

        completedOrders.forEach(order => {
            order.order_variants?.forEach(item => {
                const productId = item.product_variants.products.id;
                const productName = item.product_variants.products.nom;
                const productPrice = item.product_variants.products.prix_base;
                
                if (!salesPerProduct[productId]) {
                    salesPerProduct[productId] = {
                        id: productId,
                        name: productName,
                        price: productPrice,
                        totalSales: 0,
                        revenue: 0
                    };
                }
                salesPerProduct[productId].revenue += item.unit_price * item.quantity;
                salesPerProduct[productId].totalSales += item.quantity;
            });
        });

        const topProducts = Object.values(salesPerProduct)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 10);

        res.json(topProducts);
    } catch (error) {
        console.error('Erreur dashboard top-products:', error);
        res.status(500).json({ message: error.message });
    }
};

// Fonction utilitaire pour récupérer l'ID du vendeur
async function getVendorId(userId) {
    const { supabase } = require('../config/supabase');
    
    const { data: vendor, error } = await supabase
        .from('vendors')
        .select('id')
        .eq('user_id', userId)
        .single();
        
    if (error) {
        console.error('Erreur récupération vendeur:', error);
        return null;
    }
    
    return vendor?.id;
} 