require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const { sequelize } = require('./models');

// 3) Synchro avec la BDD
sequelize.sync({ force: process.env.NODE_ENV === 'test' })
    .then(() => {
        console.log('Database synchronized');
    })
    .catch((err) => {
        console.error('Error synchronizing database:', err);
    });

const app = express();
app.use(express.json());

// 1) Parse le JSON
app.use(bodyParser.json());

// 2) Routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

const userRoutes = require('./routes/user');
app.use('/api/users', userRoutes);

const productRoutes = require('./routes/products');
app.use('/api/products', productRoutes);

const favoriteRoutes = require('./routes/favorites');
app.use('/api/users/me/favorites', favoriteRoutes);

const cartRoutes = require('./routes/cart');
app.use('/api/cart', cartRoutes);

const orderRoutes = require('./routes/orders');
app.use('/api/orders', orderRoutes);

const paymentRoutes = require('./routes/payments');
app.use('/api/payments', paymentRoutes);

const notificationRoutes = require('./routes/notifications');
app.use('/api/notifications', notificationRoutes);

// Admin routes
const adminProductRoutes = require('./routes/admin/products');
app.use('/api/admin/products', adminProductRoutes);

const adminOrderRoutes = require('./routes/admin/orders');
app.use('/api/admin/orders', adminOrderRoutes);

const adminDashboardRoutes = require('./routes/admin/dashboard');
app.use('/api/admin/dashboard', adminDashboardRoutes);

// 3) 404 pour les routes non gérées
app.use((req, res) => {
    res.status(404).json({ message: 'Route non trouvée' });
});

module.exports = app;
