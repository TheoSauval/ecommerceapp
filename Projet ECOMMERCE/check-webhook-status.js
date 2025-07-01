require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Script pour vérifier le statut du webhook Stripe
 */
async function checkWebhookStatus() {
    console.log('🔍 Vérification du statut du webhook Stripe');
    console.log('==========================================');
    
    try {
        // Lister les webhooks existants
        const webhooks = await stripe.webhookEndpoints.list();
        
        if (webhooks.data.length === 0) {
            console.log('❌ Aucun webhook configuré');
            console.log('');
            console.log('💡 Pour configurer un webhook:');
            console.log('1. En développement, utilisez Stripe CLI:');
            console.log('   stripe listen --forward-to localhost:4000/api/payments/webhook');
            console.log('');
            console.log('2. Ou utilisez ngrok:');
            console.log('   ngrok http 4000');
            console.log('   Puis créez un webhook avec l\'URL https://...ngrok.io/api/payments/webhook');
            return;
        }
        
        console.log(`📋 ${webhooks.data.length} webhook(s) trouvé(s):`);
        console.log('');
        
        webhooks.data.forEach((webhook, index) => {
            console.log(`${index + 1}. ID: ${webhook.id}`);
            console.log(`   URL: ${webhook.url}`);
            console.log(`   Statut: ${webhook.status}`);
            console.log(`   Événements: ${webhook.enabled_events.join(', ')}`);
            console.log(`   Créé: ${new Date(webhook.created * 1000).toLocaleString()}`);
            console.log('');
        });
        
        // Vérifier les événements récents
        console.log('📊 Événements webhook récents:');
        console.log('=============================');
        
        const events = await stripe.events.list({
            limit: 10,
            types: ['checkout.session.completed', 'payment_intent.succeeded', 'payment_intent.payment_failed']
        });
        
        if (events.data.length === 0) {
            console.log('❌ Aucun événement récent trouvé');
        } else {
            events.data.forEach((event, index) => {
                console.log(`${index + 1}. Type: ${event.type}`);
                console.log(`   ID: ${event.id}`);
                console.log(`   Date: ${new Date(event.created * 1000).toLocaleString()}`);
                console.log(`   Livré: ${event.delivery_attempts?.length || 0} tentative(s)`);
                
                if (event.type === 'checkout.session.completed') {
                    const session = event.data.object;
                    console.log(`   Commande ID: ${session.metadata?.orderId || 'Non spécifié'}`);
                    console.log(`   Utilisateur ID: ${session.metadata?.userId || 'Non spécifié'}`);
                    console.log(`   Montant: ${session.amount_total / 100} ${session.currency}`);
                }
                console.log('');
            });
        }
        
        // Vérifier la configuration
        console.log('🔧 Configuration actuelle:');
        console.log('==========================');
        console.log(`STRIPE_SECRET_KEY: ${process.env.STRIPE_SECRET_KEY ? '✅ Configuré' : '❌ Manquant'}`);
        console.log(`STRIPE_WEBHOOK_SECRET: ${process.env.STRIPE_WEBHOOK_SECRET ? '✅ Configuré' : '❌ Manquant'}`);
        console.log(`WEBHOOK_URL: ${process.env.WEBHOOK_URL || 'Non configuré'}`);
        console.log(`NODE_ENV: ${process.env.NODE_ENV || 'Non configuré'}`);
        
    } catch (error) {
        console.error('❌ Erreur lors de la vérification:', error.message);
    }
}

// Exécuter la vérification
checkWebhookStatus(); 