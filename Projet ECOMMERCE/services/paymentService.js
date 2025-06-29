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
                order_variants (
                    quantity,
                    unit_price,
                    product_variants (
                        id,
                        products (
                            id,
                            nom
                        ),
                        colors (
                            nom
                        ),
                        heights (
                            nom
                        )
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
            line_items: order.order_variants.map(item => ({
                price_data: {
                    currency: 'eur',
                    product_data: {
                        name: `${item.product_variants.products.nom} (${item.product_variants.colors.nom}, ${item.product_variants.heights.nom})`,
                    },
                    unit_amount: Math.round(item.unit_price * 100), // Stripe utilise les centimes
                },
                quantity: item.quantity,
            })),
            mode: 'payment',
            success_url: `ecommerceshop://payment/success?session_id={CHECKOUT_SESSION_ID}`,
            cancel_url: `ecommerceshop://payment/cancel`,
            metadata: {
                orderId: order.id.toString(),
                userId: userId
            }
        });
        
        return { sessionId: session.id, url: session.url };
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
        console.log('🔔 Traitement webhook Stripe:', event.type);
        console.log('🔔 Données de l\'événement:', JSON.stringify(event.data.object, null, 2));
        
        switch (event.type) {
            case 'checkout.session.completed':
                const session = event.data.object;
                const orderId = parseInt(session.metadata.orderId, 10);
                const userId = session.metadata.userId;
                
                console.log(`🔔 Traitement paiement réussi pour commande ${orderId}, utilisateur ${userId}`);
                
                // Vérifier que la commande existe
                const { data: existingOrder, error: orderCheckError } = await supabase
                    .from('orders')
                    .select('*')
                    .eq('id', orderId)
                    .single();
                
                if (orderCheckError || !existingOrder) {
                    console.error(`❌ Commande ${orderId} non trouvée:`, orderCheckError);
                    break;
                }
                
                console.log(`✅ Commande ${orderId} trouvée, statut actuel: ${existingOrder.status}`);
                
                // Vérifier si un paiement existe déjà pour cette commande
                const { data: existingPayment } = await supabase
                    .from('payments')
                    .select('*')
                    .eq('order_id', orderId)
                    .single();
                
                if (existingPayment) {
                    console.log(`⚠️ Paiement déjà existant pour la commande ${orderId}:`, existingPayment.id);
                    break;
                }
                
                // 1. Mettre à jour le statut de la commande
                const { error: orderError } = await supabase
                    .from('orders')
                    .update({ status: 'Payé' })
                    .eq('id', orderId);

                if (orderError) {
                    console.error(`❌ Erreur lors de la mise à jour du statut pour la commande ${orderId}:`, orderError);
                    break;
                }
                
                console.log(`✅ Statut de la commande ${orderId} mis à jour vers 'Payé'`);
                    
                // 2. Décrémenter le stock
                const { error: stockError } = await supabase.rpc('decrease_stock', { order_id_param: orderId });

                if (stockError) {
                    console.error(`❌ Erreur lors de la décrémentation du stock pour la commande ${orderId}:`, stockError);
                } else {
                    console.log(`✅ Stock décrémenté pour la commande ${orderId}`);
                }

                // 3. Créer un enregistrement de paiement
                const paymentData = {
                    order_id: orderId,
                    user_id: userId,
                    amount: session.amount_total / 100,
                    status: 'Payé',
                    stripe_payment_intent_id: session.payment_intent
                };
                
                console.log(`🔔 Création du paiement avec les données:`, paymentData);
                
                const { data: payment, error: paymentError } = await supabase
                    .from('payments')
                    .insert([paymentData])
                    .select()
                    .single();
                
                if (paymentError) {
                    console.error(`❌ Erreur lors de la création du paiement pour la commande ${orderId}:`, paymentError);
                } else {
                    console.log(`✅ Paiement créé avec succès: ID ${payment.id}`);
                }
                break;
                
            case 'payment_intent.payment_failed':
                const paymentIntent = event.data.object;
                const failedOrderId = paymentIntent.metadata?.orderId;
                
                if (failedOrderId) {
                    console.log(`❌ Paiement échoué pour la commande ${failedOrderId}`);
                    
                    // Mettre à jour le statut de la commande
                    const { error: failedOrderError } = await supabase
                        .from('orders')
                        .update({ status: 'Échec du paiement' })
                        .eq('id', failedOrderId);
                        
                    if (failedOrderError) {
                        console.error(`❌ Erreur lors de la mise à jour du statut d'échec pour la commande ${failedOrderId}:`, failedOrderError);
                    } else {
                        console.log(`✅ Statut de la commande ${failedOrderId} mis à jour vers 'Échec du paiement'`);
                    }
                }
                break;
                
            default:
                console.log(`🔔 Événement Stripe non géré: ${event.type}`);
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