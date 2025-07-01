require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Script pour configurer le webhook Stripe avec ngrok
 */
class NgrokWebhookSetup {
    constructor() {
        this.ngrokUrl = 'https://crane-concrete-coyote.ngrok-free.app';
        this.webhookUrl = `${this.ngrokUrl}/api/payments/webhook`;
    }

    /**
     * Lister les webhooks existants
     */
    async listWebhooks() {
        console.log('📋 Liste des webhooks Stripe existants:');
        console.log('=====================================');
        
        try {
            const webhooks = await stripe.webhookEndpoints.list();
            
            if (webhooks.data.length === 0) {
                console.log('❌ Aucun webhook configuré');
                return [];
            }
            
            webhooks.data.forEach((webhook, index) => {
                console.log(`${index + 1}. ID: ${webhook.id}`);
                console.log(`   URL: ${webhook.url}`);
                console.log(`   Statut: ${webhook.status}`);
                console.log(`   Événements: ${webhook.enabled_events.join(', ')}`);
                console.log(`   Créé: ${new Date(webhook.created * 1000).toLocaleString()}`);
                console.log('');
            });
            
            return webhooks.data;
        } catch (error) {
            console.error('❌ Erreur lors de la récupération des webhooks:', error.message);
            return [];
        }
    }

    /**
     * Créer le webhook avec ngrok
     */
    async createWebhook() {
        console.log('🔧 Configuration du webhook Stripe avec ngrok...');
        console.log('===============================================');
        console.log(`🌐 URL ngrok: ${this.ngrokUrl}`);
        console.log(`🔗 URL webhook: ${this.webhookUrl}`);
        console.log('');
        
        try {
            // Supprimer les anciens webhooks si ils existent
            const existingWebhooks = await this.listWebhooks();
            for (const webhook of existingWebhooks) {
                if (webhook.url.includes('ngrok') || webhook.url.includes('localhost')) {
                    console.log(`🗑️ Suppression de l'ancien webhook: ${webhook.id}`);
                    await stripe.webhookEndpoints.del(webhook.id);
                }
            }
            
            console.log('🔧 Création du nouveau webhook...');
            
            const webhook = await stripe.webhookEndpoints.create({
                url: this.webhookUrl,
                enabled_events: [
                    'checkout.session.completed',
                    'payment_intent.payment_failed',
                    'payment_intent.succeeded',
                    'charge.succeeded',
                    'charge.updated'
                ],
                description: 'Webhook e-commerce avec ngrok'
            });
            
            console.log('✅ Webhook créé avec succès!');
            console.log(`   ID: ${webhook.id}`);
            console.log(`   URL: ${webhook.url}`);
            console.log(`   Secret: ${webhook.secret}`);
            console.log('');
            console.log('🔑 IMPORTANT: Mettez à jour votre fichier .env:');
            console.log(`   STRIPE_WEBHOOK_SECRET=${webhook.secret}`);
            console.log('');
            console.log('🧪 Test du webhook...');
            await this.testWebhook(webhook.id);
            
            return webhook;
        } catch (error) {
            console.error('❌ Erreur lors de la création du webhook:', error.message);
            
            if (error.message.includes('Invalid URL')) {
                console.log('');
                console.log('💡 Vérifiez que:');
                console.log('1. Votre serveur tourne sur le port 4000');
                console.log('2. ngrok est configuré correctement');
                console.log('3. L\'URL ngrok est accessible');
            }
            
            return null;
        }
    }

    /**
     * Tester le webhook
     */
    async testWebhook(webhookId) {
        try {
            const testEvent = await stripe.webhookEndpoints.testWebhook(webhookId, {
                checkout_session: {
                    id: 'cs_test_' + Date.now(),
                    object: 'checkout.session',
                    amount_total: 2000,
                    currency: 'eur',
                    metadata: {
                        orderId: '123',
                        userId: 'test-user-id'
                    },
                    payment_intent: 'pi_test_' + Date.now(),
                    status: 'complete'
                }
            });
            
            console.log('✅ Test webhook envoyé avec succès');
            console.log(`   ID de l'événement de test: ${testEvent.id}`);
            console.log('');
            console.log('🎉 Configuration terminée!');
            console.log('💡 Vous pouvez maintenant tester vos paiements sans Stripe CLI');
            
        } catch (error) {
            console.error('❌ Erreur lors du test du webhook:', error.message);
        }
    }

    /**
     * Vérifier la configuration
     */
    async checkConfiguration() {
        console.log('🔍 Vérification de la configuration...');
        console.log('=====================================');
        
        // Vérifier les variables d'environnement
        console.log('📋 Variables d\'environnement:');
        console.log(`   STRIPE_SECRET_KEY: ${process.env.STRIPE_SECRET_KEY ? '✅ Configurée' : '❌ Manquante'}`);
        console.log(`   STRIPE_WEBHOOK_SECRET: ${process.env.STRIPE_WEBHOOK_SECRET ? '✅ Configurée' : '❌ Manquante'}`);
        console.log(`   SUPABASE_URL: ${process.env.SUPABASE_URL ? '✅ Configurée' : '❌ Manquante'}`);
        console.log(`   SUPABASE_ANON_KEY: ${process.env.SUPABASE_ANON_KEY ? '✅ Configurée' : '❌ Manquante'}`);
        console.log('');
        
        // Vérifier les webhooks
        const webhooks = await this.listWebhooks();
        const ngrokWebhook = webhooks.find(w => w.url.includes('ngrok'));
        
        if (ngrokWebhook) {
            console.log('✅ Webhook ngrok trouvé:');
            console.log(`   URL: ${ngrokWebhook.url}`);
            console.log(`   Statut: ${ngrokWebhook.status}`);
        } else {
            console.log('❌ Aucun webhook ngrok trouvé');
        }
    }
}

/**
 * Fonction principale
 */
async function main() {
    const setup = new NgrokWebhookSetup();
    
    console.log('🚀 Configuration du webhook Stripe avec ngrok');
    console.log('=============================================');
    console.log('');
    
    const args = process.argv.slice(2);
    
    if (args.includes('--check')) {
        await setup.checkConfiguration();
    } else if (args.includes('--list')) {
        await setup.listWebhooks();
    } else if (args.includes('--create')) {
        await setup.createWebhook();
    } else {
        console.log('Usage:');
        console.log('  node setup-ngrok-webhook.js --create  # Créer le webhook');
        console.log('  node setup-ngrok-webhook.js --list    # Lister les webhooks');
        console.log('  node setup-ngrok-webhook.js --check   # Vérifier la config');
        console.log('');
        console.log('💡 Recommandé: node setup-ngrok-webhook.js --create');
    }
}

// Exécuter le script
if (require.main === module) {
    main().catch(console.error);
}

module.exports = NgrokWebhookSetup; 