const orderService = require('../services/orderService');
const productService = require('../services/productService');

// GET /api/admin/dashboard/sales
exports.getSales = async (req, res) => {
    try {
        const orders = await orderService.getCompletedOrders();
        
        const totalRevenue = orders.reduce((sum, order) => {
            return sum + (order.items?.reduce((orderSum, item) => 
                orderSum + (item.prix * item.quantite), 0) || 0);
        }, 0);

        const salesByDay = {};
        const salesByMonth = {};

        orders.forEach(order => {
            const date = new Date(order.created_at);
            const day = date.toISOString().split('T')[0];
            const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

            const orderTotal = order.items?.reduce((sum, item) => 
                sum + (item.prix * item.quantite), 0) || 0;

            salesByDay[day] = (salesByDay[day] || 0) + orderTotal;
            salesByMonth[month] = (salesByMonth[month] || 0) + orderTotal;
        });

        res.json({
            totalRevenue,
            salesByDay,
            salesByMonth
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/admin/dashboard/top-products
exports.getTopProducts = async (req, res) => {
    try {
        const orders = await orderService.getCompletedOrders();
        const salesPerProduct = {};

        orders.forEach(order => {
            order.items?.forEach(item => {
                if (!salesPerProduct[item.produit_id]) {
                    salesPerProduct[item.produit_id] = {
                        id: item.produit_id,
                        name: item.nom,
                        price: item.prix,
                        totalSales: 0,
                        revenue: 0
                    };
                }
                salesPerProduct[item.produit_id].revenue += item.prix * item.quantite;
                salesPerProduct[item.produit_id].totalSales += item.quantite;
            });
        });

        const topProducts = Object.values(salesPerProduct)
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 10);

        res.json(topProducts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 