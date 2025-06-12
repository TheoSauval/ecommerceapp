require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const { sequelize } = require('./models');
const cors = require('cors');

// 3) Synchro avec la BDD
sequelize.sync({ force: process.env.NODE_ENV === 'test' })
    .then(() => {
        console.log('Database synchronized');
    })
    .catch((err) => {
        console.error('Error synchronizing database:', err);
    });

const app = express();

// Configuration CORS
app.use(cors({
    origin: 'http://localhost:4000',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// 1) Parse le JSON
app.use(express.json());

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

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
});

module.exports = app;
