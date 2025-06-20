const { supabase } = require('../config/supabase');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

class PaymentService {
    // Récupérer les paiements d'un utilisateur
    async getPayments(userId) {
        const { data, error } = await supabase
            .from('payments')
            .select(`
                *,
                products (
                    id,
                    nom,
                    prix,
                    description
                )
            `)
            .eq('user_id', userId)
            .order('date_paiement', { ascending: false });
            
        if (error) throw error;
        return data;
    }
    
    // Récupérer un paiement par ID
    async getPaymentById(paymentId, userId) {
        const { data, error } = await supabase
            .from('payments')
            .select(`
                *,
                products (
                    id,
                    nom,
                    prix,
                    description
                )
            `)
            .eq('id', paymentId)
            .eq('user_id', userId)
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Créer un nouveau paiement
    async createPayment(paymentData) {
        const { data, error } = await supabase
            .from('payments')
            .insert([paymentData])
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Mettre à jour le statut d'un paiement
    async updatePaymentStatus(paymentId, userId, status) {
        const validStatuses = ['En attente', 'Payé', 'Remboursé'];
        
        if (!validStatuses.includes(status)) {
            throw new Error('Statut invalide');
        }
        
        // Vérifier que le paiement existe et appartient à l'utilisateur
        const { data: payment } = await supabase
            .from('payments')
            .select('*')
            .eq('id', paymentId)
            .eq('user_id', userId)
            .single();
            
        if (!payment) {
            throw new Error('Paiement non trouvé');
        }
        
        if (payment.status === 'Remboursé' && status !== 'Remboursé') {
            throw new Error('Impossible de modifier un paiement remboursé');
        }
        
        const { data, error } = await supabase
            .from('payments')
            .update({ status })
            .eq('id', paymentId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
    
    // Initier un paiement Stripe
    async initiateStripePayment(orderId, userId) {
        // Récupérer la commande
        const { data: order } = await supabase
            .from('orders')
            .select(`
                *,
                orders_products (
                    quantity,
                    unit_price,
                    products (
                        id,
                        nom,
                        prix
                    )
                )
            `)
            .eq('id', orderId)
            .eq('user_id', userId)
            .single();
            
        if (!order) {
            throw new Error('Commande non trouvée');
        }
        
        if (order.status !== 'En attente') {
            throw new Error('Cette commande ne peut plus être payée');
        }
        
        // Créer une session de paiement Stripe
        const session = await stripe.checkout.sessions.create({
            payment_method_types: ['card'],
            line_items: order.orders_products.map(item => ({
                price_data: {
                    currency: 'eur',
                    product_data: {
                        name: item.products.nom,
                    },
                    unit_amount: Math.round(item.unit_price * 100), // Stripe utilise les centimes
                },
                quantity: item.quantity,
            })),
            mode: 'payment',
            success_url: `${process.env.FRONTEND_URL}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `${process.env.FRONTEND_URL}/payment/cancel`,
            metadata: {
                orderId: order.id.toString()
            }
        });
        
        return { sessionId: session.id };
    }
    
    // Récupérer le statut d'un paiement Stripe
    async getStripePaymentStatus(orderId, userId) {
        // Vérifier que la commande appartient à l'utilisateur
        const { data: order } = await supabase
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .eq('user_id', userId)
            .single();
            
        if (!order) {
            throw new Error('Commande non trouvée');
        }
        
        // Récupérer les paiements Stripe pour cette commande
        const payments = await stripe.paymentIntents.list({
            metadata: { orderId: order.id.toString() }
        });
        
        if (payments.data.length === 0) {
            return { status: 'En attente' };
        }
        
        const payment = payments.data[0];
        return {
            status: payment.status,
            amount: payment.amount / 100, // Convertir les centimes en euros
            currency: payment.currency
        };
    }
    
    // Traiter un webhook Stripe
    async handleStripeWebhook(event) {
        switch (event.type) {
            case 'checkout.session.completed':
                const session = event.data.object;
                const orderId = session.metadata.orderId;
                
                // Mettre à jour le statut de la commande
                await supabase
                    .from('orders')
                    .update({ status: 'Payé' })
                    .eq('id', orderId);
                    
                // Créer un enregistrement de paiement
                await supabase
                    .from('payments')
                    .insert([{
                        order_id: orderId,
                        amount: session.amount_total / 100,
                        status: 'Payé',
                        stripe_payment_intent_id: session.payment_intent
                    }]);
                break;
                
            case 'payment_intent.payment_failed':
                const paymentIntent = event.data.object;
                const failedOrderId = paymentIntent.metadata.orderId;
                
                // Mettre à jour le statut de la commande
                await supabase
                    .from('orders')
                    .update({ status: 'Échec du paiement' })
                    .eq('id', failedOrderId);
                break;
        }
    }
    
    // Rembourser un paiement
    async refundPayment(paymentId, userId, amount = null) {
        // Vérifier que le paiement existe et appartient à l'utilisateur
        const { data: payment } = await supabase
            .from('payments')
            .select('*')
            .eq('id', paymentId)
            .eq('user_id', userId)
            .single();
            
        if (!payment) {
            throw new Error('Paiement non trouvé');
        }
        
        if (payment.status !== 'Payé') {
            throw new Error('Seuls les paiements payés peuvent être remboursés');
        }
        
        // Créer le remboursement Stripe
        const refundAmount = amount ? Math.round(amount * 100) : Math.round(payment.prix_total * 100);
        const refund = await stripe.refunds.create({
            payment_intent: payment.stripe_payment_intent_id,
            amount: refundAmount
        });
        
        // Mettre à jour le statut du paiement
        const { data, error } = await supabase
            .from('payments')
            .update({ 
                status: 'Remboursé',
                refund_amount: refundAmount / 100
            })
            .eq('id', paymentId)
            .select()
            .single();
            
        if (error) throw error;
        return data;
    }
}

module.exports = new PaymentService(); 