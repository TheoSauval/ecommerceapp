require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

// Configuration Supabase
const { supabase } = require('./config/supabase');

const app = express();

// Middleware de logging pour toutes les requêtes
app.use((req, res, next) => {
    console.log(`🌐 ${req.method} ${req.path}`);
    console.log('📋 Headers:', req.headers);
    next();
});

// Configuration CORS
app.use(cors({
    origin: ['http://localhost:3000', 'http://localhost:4000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-client-type'],
    credentials: true
}));

// 1) Parse le JSON
app.use((req, res, next) => {
    // Si c'est le webhook Stripe, on utilise express.raw
    if (req.originalUrl === '/api/payments/webhook') {
        express.raw({ type: 'application/json' })(req, res, next);
    } else {
        express.json()(req, res, next);
    }
});

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

// Démarrer le nettoyage automatique des commandes orphelines
const orderService = require('./services/orderService');
orderService.startAutoCleanup();

const paymentRoutes = require('./routes/payments');
app.use('/api/payments', paymentRoutes);

const notificationRoutes = require('./routes/notifications');
app.use('/api/notifications', notificationRoutes);

// Routes de recommandations
const recommendationRoutes = require('./routes/recommendations');
app.use('/api/recommendations', recommendationRoutes);

// Routes d'analyses vendeur
const vendorAnalyticsRoutes = require('./routes/vendorAnalytics');
app.use('/api/vendor-analytics', vendorAnalyticsRoutes);

// Admin routes
const adminProductRoutes = require('./routes/admin/products');
app.use('/api/admin/products', adminProductRoutes);

const adminOrderRoutes = require('./routes/admin/orders');
app.use('/api/admin/orders', adminOrderRoutes);

const adminDashboardRoutes = require('./routes/admin/dashboard');
app.use('/api/admin/dashboard', adminDashboardRoutes);

const adminUploadRoutes = require('./routes/admin/upload');
app.use('/api/admin/upload', adminUploadRoutes);

app.get('/test', (req, res) => {
    res.json({ message: 'API OK - Supabase Migration Complete' });
});

// 3) 404 pour les routes non gérées
app.use((req, res) => {
    console.log('❌ Route non trouvée:', req.method, req.path);
    res.status(404).json({ message: 'Route non trouvée' });
});

// Démarrage du serveur
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
    console.log(`🚀 Serveur démarré sur le port ${PORT}`);
    console.log(`📊 Base de données: Supabase`);
});

module.exports = app;
