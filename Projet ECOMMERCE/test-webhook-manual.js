require('dotenv').config();
const { supabase } = require('./config/supabase');
const paymentService = require('./services/paymentService');

/**
 * Script pour tester manuellement le webhook avec une commande existante
 */
async function testWebhookManual() {
    console.log('🧪 Test manuel du webhook Stripe');
    console.log('===============================');
    
    try {
        // Récupérer une commande récente en attente
        const { data: orders, error: ordersError } = await supabase
            .from('orders')
            .select('*')
            .eq('status', 'En attente')
            .order('created_at', { ascending: false })
            .limit(1);
        
        if (ordersError) {
            console.error('❌ Erreur lors de la récupération des commandes:', ordersError);
            return;
        }
        
        if (!orders || orders.length === 0) {
            console.log('❌ Aucune commande en attente trouvée');
            return;
        }
        
        const order = orders[0];
        console.log(`📋 Commande trouvée: ID ${order.id}, utilisateur ${order.user_id}`);
        console.log(`   Statut: ${order.status}`);
        console.log(`   Créée: ${new Date(order.created_at).toLocaleString()}`);
        console.log('');
        
        // Simuler un événement webhook
        const mockEvent = {
            id: 'evt_test_' + Date.now(),
            type: 'checkout.session.completed',
            data: {
                object: {
                    id: 'cs_test_' + Date.now(),
                    amount_total: 2000, // 20.00 EUR en centimes
                    currency: 'eur',
                    metadata: {
                        orderId: order.id,
                        userId: order.user_id
                    },
                    payment_intent: 'pi_test_' + Date.now(),
                    status: 'complete'
                }
            }
        };
        
        console.log('🔔 Simulation d\'un événement webhook:');
        console.log(`   Type: ${mockEvent.type}`);
        console.log(`   Commande ID: ${mockEvent.data.object.metadata.orderId}`);
        console.log(`   Utilisateur ID: ${mockEvent.data.object.metadata.userId}`);
        console.log(`   Montant: ${mockEvent.data.object.amount_total / 100} ${mockEvent.data.object.currency}`);
        console.log('');
        
        // Traiter l'événement
        console.log('🔄 Traitement de l\'événement...');
        await paymentService.handleStripeWebhook(mockEvent);
        
        // Vérifier le résultat
        console.log('✅ Vérification du résultat...');
        
        // Vérifier le statut de la commande
        const { data: updatedOrder, error: orderCheckError } = await supabase
            .from('orders')
            .select('*')
            .eq('id', order.id)
            .single();
        
        if (orderCheckError) {
            console.error('❌ Erreur lors de la vérification de la commande:', orderCheckError);
        } else {
            console.log(`📋 Statut de la commande après traitement: ${updatedOrder.status}`);
        }
        
        // Vérifier le paiement créé
        const { data: payments, error: paymentsError } = await supabase
            .from('payments')
            .select('*')
            .eq('order_id', order.id);
        
        if (paymentsError) {
            console.error('❌ Erreur lors de la vérification des paiements:', paymentsError);
        } else if (payments && payments.length > 0) {
            console.log(`💰 Paiement créé: ID ${payments[0].id}, statut ${payments[0].status}`);
            console.log(`   Montant: ${payments[0].amount} EUR`);
        } else {
            console.log('❌ Aucun paiement créé');
        }
        
    } catch (error) {
        console.error('❌ Erreur lors du test:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

// Exécuter le test
testWebhookManual(); 