require('dotenv').config();
const { supabase } = require('./config/supabase');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Test rapide de la configuration des paiements
 */
class QuickPaymentTest {
    constructor() {
        this.testUserId = null;
        this.testOrderId = null;
    }

    /**
     * Test 1: Vérifier la configuration de base
     */
    async testBasicConfiguration() {
        console.log('🔍 Test 1: Vérification de la configuration de base');
        console.log('================================================');
        
        // Vérifier les variables d'environnement
        const config = {
            stripeSecretKey: process.env.STRIPE_SECRET_KEY ? '✅ Configurée' : '❌ Manquante',
            stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET ? '✅ Configurée' : '❌ Manquante',
            supabaseUrl: process.env.SUPABASE_URL ? '✅ Configurée' : '❌ Manquante',
            supabaseKey: process.env.SUPABASE_ANON_KEY ? '✅ Configurée' : '❌ Manquante'
        };
        
        console.log('📋 Configuration:');
        Object.entries(config).forEach(([key, value]) => {
            console.log(`   ${key}: ${value}`);
        });
        
        // Vérifier la connexion Stripe
        try {
            const account = await stripe.accounts.retrieve();
            console.log(`✅ Connexion Stripe OK - Mode: ${account.charges_enabled ? 'Production' : 'Test'}`);
        } catch (error) {
            console.log(`❌ Erreur connexion Stripe: ${error.message}`);
        }
        
        // Vérifier la connexion Supabase
        try {
            const { data, error } = await supabase.from('user_profiles').select('count').limit(1);
            if (error) throw error;
            console.log('✅ Connexion Supabase OK');
        } catch (error) {
            console.log(`❌ Erreur connexion Supabase: ${error.message}`);
        }
        
        console.log('');
    }

    /**
     * Test 2: Vérifier les webhooks Stripe
     */
    async testWebhooks() {
        console.log('🔍 Test 2: Vérification des webhooks Stripe');
        console.log('==========================================');
        
        try {
            const webhooks = await stripe.webhookEndpoints.list();
            
            if (webhooks.data.length === 0) {
                console.log('❌ Aucun webhook configuré');
                console.log('💡 Utilisez: node setup-stripe-webhook.js --create');
                return false;
            }
            
            console.log(`✅ ${webhooks.data.length} webhook(s) trouvé(s):`);
            webhooks.data.forEach((webhook, index) => {
                console.log(`   ${index + 1}. ${webhook.url} (${webhook.status})`);
                console.log(`      Événements: ${webhook.enabled_events.join(', ')}`);
            });
            
            return true;
        } catch (error) {
            console.log(`❌ Erreur lors de la vérification des webhooks: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 3: Vérifier la structure de la base de données
     */
    async testDatabaseStructure() {
        console.log('🔍 Test 3: Vérification de la structure de la base de données');
        console.log('==========================================================');
        
        const tables = ['user_profiles', 'orders', 'payments', 'product_variants', 'order_variants'];
        
        for (const table of tables) {
            try {
                const { data, error } = await supabase.from(table).select('count').limit(1);
                if (error) throw error;
                console.log(`✅ Table ${table}: OK`);
            } catch (error) {
                console.log(`❌ Table ${table}: ${error.message}`);
            }
        }
        
        // Vérifier la fonction decrease_stock
        try {
            const { error } = await supabase.rpc('decrease_stock', { order_id_param: 999999 });
            // On s'attend à une erreur car la commande n'existe pas, mais la fonction doit exister
            if (error && error.message.includes('function')) {
                console.log('❌ Fonction decrease_stock: Non trouvée');
            } else {
                console.log('✅ Fonction decrease_stock: OK');
            }
        } catch (error) {
            console.log('✅ Fonction decrease_stock: OK');
        }
        
        console.log('');
    }

    /**
     * Test 4: Créer un utilisateur de test
     */
    async createTestUser() {
        console.log('🔍 Test 4: Création d\'un utilisateur de test');
        console.log('============================================');
        
        try {
            const testEmail = `test-${Date.now()}@example.com`;
            
            // Créer un utilisateur dans auth.users (simulation)
            const { data: user, error: userError } = await supabase.auth.signUp({
                email: testEmail,
                password: 'testpassword123',
                options: {
                    data: {
                        nom: 'Test',
                        prenom: 'User',
                        age: 25,
                        role: 'user'
                    }
                }
            });
            
            if (userError) throw userError;
            
            this.testUserId = user.user.id;
            console.log(`✅ Utilisateur de test créé: ${this.testUserId}`);
            
            return true;
        } catch (error) {
            console.log(`❌ Erreur création utilisateur: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 5: Créer une commande de test
     */
    async createTestOrder() {
        console.log('🔍 Test 5: Création d\'une commande de test');
        console.log('==========================================');
        
        if (!this.testUserId) {
            console.log('❌ Utilisateur de test non créé');
            return false;
        }
        
        try {
            // Récupérer une variante de produit existante
            const { data: variants, error: variantError } = await supabase
                .from('product_variants')
                .select('id, stock')
                .limit(1);
            
            if (variantError || !variants.length) {
                console.log('❌ Aucune variante de produit trouvée');
                return false;
            }
            
            const variant = variants[0];
            
            // Créer une commande
            const { data: order, error: orderError } = await supabase
                .from('orders')
                .insert([{
                    prix_total: 29.99,
                    status: 'En attente',
                    user_id: this.testUserId,
                    adresse_livraison: '123 Test Street, Test City',
                    methode_paiement: 'Stripe'
                }])
                .select()
                .single();
            
            if (orderError) throw orderError;
            
            this.testOrderId = order.id;
            console.log(`✅ Commande de test créée: ${this.testOrderId}`);
            
            // Créer un élément de commande
            const { error: orderVariantError } = await supabase
                .from('order_variants')
                .insert([{
                    order_id: order.id,
                    variant_id: variant.id,
                    quantity: 1,
                    unit_price: 29.99
                }]);
            
            if (orderVariantError) throw orderVariantError;
            
            console.log('✅ Élément de commande créé');
            return true;
            
        } catch (error) {
            console.log(`❌ Erreur création commande: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 6: Tester la création d'une session Stripe
     */
    async testStripeSession() {
        console.log('🔍 Test 6: Test de création de session Stripe');
        console.log('===========================================');
        
        if (!this.testOrderId) {
            console.log('❌ Commande de test non créée');
            return false;
        }
        
        try {
            // Récupérer la commande avec ses variantes
            const { data: order, error: orderError } = await supabase
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
                .eq('id', this.testOrderId)
                .single();
            
            if (orderError) throw orderError;
            
            // Créer une session Stripe
            const session = await stripe.checkout.sessions.create({
                payment_method_types: ['card'],
                line_items: order.order_variants.map(item => ({
                    price_data: {
                        currency: 'eur',
                        product_data: {
                            name: `${item.product_variants.products.nom} (${item.product_variants.colors.nom}, ${item.product_variants.heights.nom})`,
                        },
                        unit_amount: Math.round(item.unit_price * 100),
                    },
                    quantity: item.quantity,
                })),
                mode: 'payment',
                success_url: `ecommerceshop://payment/success?session_id={CHECKOUT_SESSION_ID}`,
                cancel_url: `ecommerceshop://payment/cancel`,
                metadata: {
                    orderId: order.id.toString(),
                    userId: this.testUserId
                }
            });
            
            console.log(`✅ Session Stripe créée: ${session.id}`);
            console.log(`   URL: ${session.url}`);
            console.log(`   Montant: ${session.amount_total / 100}€`);
            
            return session;
            
        } catch (error) {
            console.log(`❌ Erreur création session Stripe: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 7: Simuler un webhook de paiement réussi
     */
    async simulateSuccessfulPayment(session) {
        console.log('🔍 Test 7: Simulation d\'un paiement réussi');
        console.log('==========================================');
        
        try {
            // Simuler l'événement checkout.session.completed
            const event = {
                type: 'checkout.session.completed',
                data: {
                    object: {
                        id: session.id,
                        amount_total: session.amount_total,
                        currency: session.currency,
                        metadata: session.metadata,
                        payment_intent: `pi_test_${Date.now()}`,
                        status: 'complete'
                    }
                }
            };
            
            // Importer et utiliser le service de paiement
            const paymentService = require('./services/paymentService');
            await paymentService.handleStripeWebhook(event);
            
            console.log('✅ Webhook simulé avec succès');
            
            // Vérifier que le paiement a été créé
            const { data: payment, error: paymentError } = await supabase
                .from('payments')
                .select('*')
                .eq('order_id', this.testOrderId)
                .single();
            
            if (paymentError) {
                console.log('❌ Paiement non trouvé dans la base de données');
                return false;
            }
            
            console.log(`✅ Paiement créé: ID ${payment.id}, Statut: ${payment.status}`);
            
            // Vérifier que la commande a été mise à jour
            const { data: updatedOrder, error: orderError } = await supabase
                .from('orders')
                .select('status')
                .eq('id', this.testOrderId)
                .single();
            
            if (orderError) {
                console.log('❌ Erreur lors de la vérification de la commande');
                return false;
            }
            
            console.log(`✅ Statut de la commande mis à jour: ${updatedOrder.status}`);
            
            return true;
            
        } catch (error) {
            console.log(`❌ Erreur simulation webhook: ${error.message}`);
            return false;
        }
    }

    /**
     * Nettoyer les données de test
     */
    async cleanup() {
        console.log('🧹 Nettoyage des données de test...');
        
        if (this.testOrderId) {
            try {
                await supabase.from('order_variants').delete().eq('order_id', this.testOrderId);
                await supabase.from('orders').delete().eq('id', this.testOrderId);
                console.log('✅ Commande de test supprimée');
            } catch (error) {
                console.log(`⚠️ Erreur lors du nettoyage: ${error.message}`);
            }
        }
        
        if (this.testUserId) {
            try {
                await supabase.from('user_profiles').delete().eq('id', this.testUserId);
                console.log('✅ Utilisateur de test supprimé');
            } catch (error) {
                console.log(`⚠️ Erreur lors du nettoyage: ${error.message}`);
            }
        }
    }

    /**
     * Exécuter tous les tests
     */
    async runAllTests() {
        console.log('🚀 TEST RAPIDE DE LA CONFIGURATION DES PAIEMENTS');
        console.log('===============================================');
        console.log('');
        
        try {
            await this.testBasicConfiguration();
            await this.testWebhooks();
            await this.testDatabaseStructure();
            
            const userCreated = await this.createTestUser();
            if (userCreated) {
                const orderCreated = await this.createTestOrder();
                if (orderCreated) {
                    const session = await this.testStripeSession();
                    if (session) {
                        await this.simulateSuccessfulPayment(session);
                    }
                }
            }
            
            console.log('');
            console.log('🎉 TESTS TERMINÉS');
            console.log('================');
            console.log('💡 Si tous les tests sont passés, votre configuration est correcte.');
            console.log('💡 Si des erreurs apparaissent, consultez le guide de dépannage.');
            
        } catch (error) {
            console.error('❌ Erreur lors des tests:', error);
        } finally {
            await this.cleanup();
        }
    }
}

// Exécution du script
if (require.main === module) {
    const test = new QuickPaymentTest();
    test.runAllTests().catch(console.error);
}

module.exports = QuickPaymentTest; 