require('dotenv').config();
const { Paiement, Produit } = require('../models');
console.log('Stripe key exists:', !!process.env.STRIPE_SECRET_KEY);
console.log('Stripe key length:', process.env.STRIPE_SECRET_KEY ? process.env.STRIPE_SECRET_KEY.length : 0);
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// GET /api/payments
exports.getPayments = async (req, res) => {
    try {
        const payments = await Paiement.findAll({
            where: { user_id: req.user.id },
            include: [{ model: Produit }],
            order: [['date_paiement', 'DESC']]
        });
        res.json(payments);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/payments/:id
exports.getPaymentById = async (req, res) => {
    try {
        const payment = await Paiement.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id
            },
            include: [{ model: Produit }]
        });
        if (!payment) {
            return res.status(404).json({ message: 'Paiement non trouvé' });
        }
        res.json(payment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/payments
exports.createPayment = async (req, res) => {
    try {
        const { produit_id, prix_total } = req.body;

        const product = await Produit.findByPk(produit_id);
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }

        const payment = await Paiement.create({
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
        const validStatuses = ['En attente', 'Payé', 'Remboursé'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Statut invalide' });
        }

        const payment = await Paiement.findOne({
            where: {
                id: req.params.id,
                user_id: req.user.id
            }
        });

        if (!payment) {
            return res.status(404).json({ message: 'Paiement non trouvé' });
        }

        if (payment.status === 'Remboursé' && status !== 'Remboursé') {
            return res.status(400).json({ message: 'Impossible de modifier un paiement remboursé' });
        }

        await payment.update({ status });
        res.json(payment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// POST /api/payments
exports.initiatePayment = async (req, res) => {
    try {
        const { orderId } = req.body;
        
        const order = await Order.findOne({
            _id: orderId,
            user: req.user.id
        });

        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        if (order.status !== 'En attente de paiement') {
            return res.status(400).json({ message: 'Cette commande ne peut plus être payée' });
        }

        // Créer une session de paiement Stripe
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: order.items.map(item => ({
                price_data: {
                    currency: 'eur',
                    product_data: {
                        name: item.product.name,
                    },
                    unit_amount: item.price * 100, // Stripe utilise les centimes
                },
                quantity: item.quantity,
            })),
            mode: 'payment',
            success_url: `${process.env.FRONTEND_URL}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${process.env.FRONTEND_URL}/payment/cancel`,
            metadata: {
                orderId: order._id.toString()
            }
        });

        res.json({ sessionId: session.id });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// GET /api/payments/:orderId
exports.getPaymentStatus = async (req, res) => {
    try {
        const order = await Order.findOne({
            _id: req.params.orderId,
            user: req.user.id
        });

        if (!order) {
            return res.status(404).json({ message: 'Commande non trouvée' });
        }

        // Récupérer les paiements Stripe pour cette commande
        const payments = await stripe.paymentIntents.list({
            metadata: { orderId: order._id.toString() }
        });

        if (payments.data.length === 0) {
            return res.json({ status: 'En attente' });
        }

        const payment = payments.data[0];
        res.json({
            status: payment.status,
            amount: payment.amount / 100, // Convertir les centimes en euros
            currency: payment.currency
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
}; 