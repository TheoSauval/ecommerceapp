require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Script pour configurer et tester les webhooks Stripe
 */
class StripeWebhookSetup {
    constructor() {
        // En développement, utiliser l'URL de Stripe CLI si disponible
        this.webhookUrl = process.env.WEBHOOK_URL || 
                         process.env.STRIPE_CLI_WEBHOOK_URL || 
                         'http://localhost:4000/api/payments/webhook';
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
     * Créer un nouveau webhook
     */
    async createWebhook() {
        console.log('🔧 Création d\'un nouveau webhook Stripe...');
        console.log('=====================================');
        
        // Vérifier si on est en mode développement
        const isDevelopment = process.env.NODE_ENV === 'development' || 
                            this.webhookUrl.includes('localhost') ||
                            this.webhookUrl.includes('127.0.0.1');
        
        if (isDevelopment) {
            console.log('🔍 Mode développement détecté');
            console.log('💡 Pour les webhooks en développement, utilisez Stripe CLI:');
            console.log('   stripe listen --forward-to localhost:4000/api/payments/webhook');
            console.log('');
            console.log('🔗 L\'URL du webhook sera fournie par Stripe CLI');
            console.log('📋 Exemple: https://webhook.site/abc123...');
            console.log('');
            
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            const question = (query) => new Promise((resolve) => rl.question(query, resolve));
            
            try {
                const webhookUrl = await question('Entrez l\'URL du webhook fournie par Stripe CLI: ');
                rl.close();
                
                if (!webhookUrl.trim()) {
                    console.log('❌ URL du webhook requise');
                    return null;
                }
                
                return await this.createWebhookWithUrl(webhookUrl.trim());
            } catch (error) {
                rl.close();
                console.log('❌ Erreur lors de la saisie');
                return null;
            }
        } else {
            return await this.createWebhookWithUrl(this.webhookUrl);
        }
    }

    /**
     * Créer un webhook avec une URL spécifique
     */
    async createWebhookWithUrl(webhookUrl) {
        try {
            console.log(`🔧 Création du webhook avec l'URL: ${webhookUrl}`);
            
            const webhook = await stripe.webhookEndpoints.create({
                url: webhookUrl,
                enabled_events: [
                    'checkout.session.completed',
                    'payment_intent.payment_failed',
                    'payment_intent.succeeded'
                ],
                description: 'Webhook e-commerce pour les paiements'
            });
            
            console.log('✅ Webhook créé avec succès!');
            console.log(`   ID: ${webhook.id}`);
            console.log(`   URL: ${webhook.url}`);
            console.log(`   Secret: ${webhook.secret}`);
            console.log('');
            console.log('🔑 IMPORTANT: Ajoutez cette clé à votre fichier .env:');
            console.log(`   STRIPE_WEBHOOK_SECRET=${webhook.secret}`);
            console.log('');
            
            return webhook;
        } catch (error) {
            console.error('❌ Erreur lors de la création du webhook:', error.message);
            
            if (error.message.includes('Invalid URL')) {
                console.log('');
                console.log('💡 Solutions:');
                console.log('1. Utilisez Stripe CLI pour le développement:');
                console.log('   stripe listen --forward-to localhost:4000/api/payments/webhook');
                console.log('');
                console.log('2. Ou utilisez un service comme ngrok:');
                console.log('   ngrok http 4000');
                console.log('   Puis utilisez l\'URL https://...ngrok.io/api/payments/webhook');
                console.log('');
                console.log('3. Ou déployez votre serveur pour la production');
            }
            
            return null;
        }
    }

    /**
     * Instructions pour Stripe CLI
     */
    showStripeCLIInstructions() {
        console.log('🔧 Instructions pour Stripe CLI');
        console.log('==============================');
        console.log('');
        console.log('1. Installez Stripe CLI:');
        console.log('   brew install stripe/stripe-cli/stripe');
        console.log('');
        console.log('2. Connectez-vous:');
        console.log('   stripe login');
        console.log('');
        console.log('3. Démarrez l\'écoute des webhooks:');
        console.log('   stripe listen --forward-to localhost:4000/api/payments/webhook');
        console.log('');
        console.log('4. Copiez l\'URL du webhook affichée et utilisez-la pour créer le webhook');
        console.log('');
    }

    /**
     * Supprimer un webhook
     */
    async deleteWebhook(webhookId) {
        console.log(`🗑️ Suppression du webhook ${webhookId}...`);
        
        try {
            await stripe.webhookEndpoints.del(webhookId);
            console.log('✅ Webhook supprimé avec succès');
        } catch (error) {
            console.error('❌ Erreur lors de la suppression:', error);
        }
    }

    /**
     * Tester un webhook
     */
    async testWebhook(webhookId) {
        console.log(`🧪 Test du webhook ${webhookId}...`);
        
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
            
        } catch (error) {
            console.error('❌ Erreur lors du test webhook:', error.message);
        }
    }

    /**
     * Vérifier la configuration actuelle
     */
    async checkConfiguration() {
        console.log('🔍 Vérification de la configuration Stripe...');
        console.log('=====================================');
        
        console.log(`📋 URL du webhook: ${this.webhookUrl}`);
        console.log(`🔑 Clé secrète Stripe: ${process.env.STRIPE_SECRET_KEY ? '✅ Configurée' : '❌ Manquante'}`);
        console.log(`🔐 Secret webhook: ${process.env.STRIPE_WEBHOOK_SECRET ? '✅ Configuré' : '❌ Manquant'}`);
        console.log('');
        
        if (!process.env.STRIPE_SECRET_KEY) {
            console.log('⚠️ STRIPE_SECRET_KEY manquante dans le fichier .env');
        }
        
        if (!process.env.STRIPE_WEBHOOK_SECRET) {
            console.log('⚠️ STRIPE_WEBHOOK_SECRET manquante dans le fichier .env');
        }
        
        // Vérifier si Stripe CLI est disponible
        const { execSync } = require('child_process');
        try {
            execSync('stripe --version', { stdio: 'ignore' });
            console.log('✅ Stripe CLI installé');
        } catch (error) {
            console.log('❌ Stripe CLI non installé');
            console.log('💡 Installez-le avec: brew install stripe/stripe-cli/stripe');
        }
    }

    /**
     * Menu interactif
     */
    async showMenu() {
        console.log('🔧 Configuration des webhooks Stripe');
        console.log('=====================================');
        console.log('1. Lister les webhooks existants');
        console.log('2. Créer un nouveau webhook');
        console.log('3. Supprimer un webhook');
        console.log('4. Tester un webhook');
        console.log('5. Vérifier la configuration');
        console.log('6. Instructions Stripe CLI');
        console.log('7. Quitter');
        console.log('');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        const question = (query) => new Promise((resolve) => rl.question(query, resolve));
        
        try {
            const choice = await question('Choisissez une option (1-7): ');
            
            switch (choice.trim()) {
                case '1':
                    await this.listWebhooks();
                    break;
                case '2':
                    await this.createWebhook();
                    break;
                case '3':
                    const webhooks = await this.listWebhooks();
                    if (webhooks.length > 0) {
                        const webhookId = await question('Entrez l\'ID du webhook à supprimer: ');
                        await this.deleteWebhook(webhookId.trim());
                    }
                    break;
                case '4':
                    const webhooks2 = await this.listWebhooks();
                    if (webhooks2.length > 0) {
                        const webhookId = await question('Entrez l\'ID du webhook à tester: ');
                        await this.testWebhook(webhookId.trim());
                    }
                    break;
                case '5':
                    await this.checkConfiguration();
                    break;
                case '6':
                    this.showStripeCLIInstructions();
                    break;
                case '7':
                    console.log('👋 Au revoir!');
                    break;
                default:
                    console.log('❌ Option invalide');
            }
        } catch (error) {
            console.error('❌ Erreur:', error.message);
        } finally {
            rl.close();
        }
    }
}

// Exécution du script
async function main() {
    const setup = new StripeWebhookSetup();
    
    if (process.argv.includes('--menu')) {
        await setup.showMenu();
    } else if (process.argv.includes('--list')) {
        await setup.listWebhooks();
    } else if (process.argv.includes('--create')) {
        await setup.createWebhook();
    } else if (process.argv.includes('--check')) {
        await setup.checkConfiguration();
    } else if (process.argv.includes('--cli-instructions')) {
        setup.showStripeCLIInstructions();
    } else {
        console.log('🔧 Script de configuration des webhooks Stripe');
        console.log('=====================================');
        console.log('Usage:');
        console.log('  node setup-stripe-webhook.js --menu              # Menu interactif');
        console.log('  node setup-stripe-webhook.js --list              # Lister les webhooks');
        console.log('  node setup-stripe-webhook.js --create            # Créer un webhook');
        console.log('  node setup-stripe-webhook.js --check             # Vérifier la config');
        console.log('  node setup-stripe-webhook.js --cli-instructions  # Instructions CLI');
        console.log('');
        await setup.checkConfiguration();
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = StripeWebhookSetup; 