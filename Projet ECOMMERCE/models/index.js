// Export des services Supabase - Plus besoin des modèles Sequelize
const authService = require('../services/authService');
const userService = require('../services/userService');
const productService = require('../services/productService');
const orderService = require('../services/orderService');
const paymentService = require('../services/paymentService');
const notificationService = require('../services/notificationService');
const cartService = require('../services/cartService');
const favoriteService = require('../services/favoriteService');

module.exports = {
    authService,
    userService,
    productService,
    orderService,
    paymentService,
    notificationService,
    cartService,
    favoriteService
};
