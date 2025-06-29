require('dotenv').config();
const paymentService = require('../services/paymentService');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// GET /api/payments
exports.getPayments = async (req, res) => {
    try {
        const payments = await paymentService.getPayments(req.user.id);
        res.json(payments);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/payments/:id
exports.getPaymentById = async (req, res) => {
    try {
        const payment = await paymentService.getPaymentById(req.params.id, req.user.id);
        res.json(payment);
    } catch (error) {
        res.status(404).json({ message: 'Paiement non trouvé' });
    }
};

// POST /api/payments
exports.createPayment = async (req, res) => {
    try {
        const { produit_id, prix_total } = req.body;

        const payment = await paymentService.createPayment({
            produit_id,
            prix_total,
            status: 'En attente',
            user_id: req.user.id
        });

        res.status(201).json(payment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// PUT /api/payments/:id/status
exports.updatePaymentStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const payment = await paymentService.updatePaymentStatus(req.params.id, req.user.id, status);
        res.json(payment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/payments/stripe/initiate
exports.initiatePayment = async (req, res) => {
    try {
        const { orderId } = req.body;
        const result = await paymentService.initiateStripePayment(orderId, req.user.id);
        console.log('DEBUG /api/payments/stripe/initiate result:', result);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/payments/stripe/:orderId/status
exports.getPaymentStatus = async (req, res) => {
    try {
        const result = await paymentService.getStripePaymentStatus(req.params.orderId, req.user.id);
        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/payments/webhook
exports.handleWebhook = async (req, res) => {
    try {
        const sig = req.headers['stripe-signature'];
        console.log('🔔 Réception webhook Stripe');
        console.log('📋 Headers reçus:', Object.keys(req.headers));
        console.log('📋 Signature Stripe:', sig ? 'Présente' : 'Absente');
        console.log('📋 Body length:', req.body ? req.body.length : 'undefined');
        
        if (!process.env.STRIPE_WEBHOOK_SECRET) {
            console.warn('⚠️ STRIPE_WEBHOOK_SECRET non configuré, webhook ignoré');
            return res.status(200).json({ received: true, warning: 'Webhook secret non configuré' });
        }
        
        if (!sig) {
            console.error('❌ Signature Stripe manquante');
            return res.status(400).json({ message: 'Signature Stripe manquante' });
        }
        
        const event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
        console.log('🔔 Stripe event reçu:', event.type);
        console.log('🔔 Event ID:', event.id);
        
        await paymentService.handleStripeWebhook(event);
        
        console.log('✅ Webhook traité avec succès');
        res.json({ received: true, event_type: event.type });
        
    } catch (error) {
        console.error('❌ Erreur Stripe webhook:', error.message);
        console.error('❌ Stack trace:', error.stack);
        
        if (error.type === 'StripeSignatureVerificationError') {
            console.error('❌ Erreur de vérification de signature Stripe');
            return res.status(400).json({ 
                message: 'Erreur de vérification de signature',
                error: error.message 
            });
        }
        
        res.status(400).json({ 
            message: 'Erreur lors du traitement du webhook',
            error: error.message 
        });
    }
}; 