require('dotenv').config();
const { supabase } = require('./config/supabase');

/**
 * Test de création de commande
 */
class OrderCreationTest {
    constructor() {
        this.testUserId = null;
        this.testOrderId = null;
    }

    /**
     * Test 1: Créer un utilisateur de test
     */
    async createTestUser() {
        console.log('🔍 Test 1: Création d\'un utilisateur de test');
        console.log('============================================');
        
        try {
            const testEmail = `test-order-${Date.now()}@example.com`;
            
            // Créer un utilisateur dans auth.users (simulation)
            const { data: user, error: userError } = await supabase.auth.signUp({
                email: testEmail,
                password: 'testpassword123',
                options: {
                    data: {
                        nom: 'Test',
                        prenom: 'Order',
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
     * Test 2: Récupérer des variantes de produits
     */
    async getTestVariants() {
        console.log('🔍 Test 2: Récupération de variantes de test');
        console.log('===========================================');
        
        try {
            const { data: variants, error: variantError } = await supabase
                .from('product_variants')
                .select('id, stock, prix, products (id, prix_base)')
                .limit(2);
            
            if (variantError || !variants.length) {
                console.log('❌ Aucune variante de produit trouvée');
                return null;
            }
            
            console.log(`✅ ${variants.length} variantes trouvées:`);
            variants.forEach(variant => {
                console.log(`   - ID: ${variant.id}, Stock: ${variant.stock}, Prix: ${variant.prix || variant.products?.prix_base}`);
            });
            
            return variants;
        } catch (error) {
            console.log(`❌ Erreur récupération variantes: ${error.message}`);
            return null;
        }
    }

    /**
     * Test 3: Créer une commande via l'API
     */
    async createOrderViaAPI(variants) {
        console.log('🔍 Test 3: Création de commande via API');
        console.log('======================================');
        
        if (!this.testUserId) {
            console.log('❌ Utilisateur de test non créé');
            return false;
        }
        
        try {
            // Simuler une requête API
            const orderData = {
                items: variants.map(variant => ({
                    variantId: variant.id,
                    quantity: 1
                })),
                adresse_livraison: '123 Test Street, Test City',
                methode_paiement: 'Stripe'
            };
            
            console.log('📋 Données de commande:', orderData);
            
            // Utiliser le service directement
            const orderService = require('./services/orderService');
            const order = await orderService.createOrder(this.testUserId, orderData);
            
            this.testOrderId = order.id;
            console.log(`✅ Commande créée avec succès: ID ${order.id}`);
            console.log(`   Statut: ${order.status}`);
            console.log(`   Prix total: ${order.prix_total}€`);
            
            return true;
        } catch (error) {
            console.log(`❌ Erreur création commande: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 4: Vérifier que la commande existe
     */
    async verifyOrder() {
        console.log('🔍 Test 4: Vérification de la commande');
        console.log('=====================================');
        
        if (!this.testOrderId) {
            console.log('❌ Commande de test non créée');
            return false;
        }
        
        try {
            // Vérifier la commande
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
                            )
                        )
                    )
                `)
                .eq('id', this.testOrderId)
                .single();
            
            if (orderError) throw orderError;
            
            console.log(`✅ Commande vérifiée:`);
            console.log(`   ID: ${order.id}`);
            console.log(`   Statut: ${order.status}`);
            console.log(`   Prix total: ${order.prix_total}€`);
            console.log(`   Variantes: ${order.order_variants.length}`);
            
            return true;
        } catch (error) {
            console.log(`❌ Erreur vérification commande: ${error.message}`);
            return false;
        }
    }

    /**
     * Test 5: Tester l'initiation du paiement
     */
    async testPaymentInitiation() {
        console.log('🔍 Test 5: Test d\'initiation du paiement');
        console.log('========================================');
        
        if (!this.testOrderId) {
            console.log('❌ Commande de test non créée');
            return false;
        }
        
        try {
            // Utiliser le service de paiement
            const paymentService = require('./services/paymentService');
            const result = await paymentService.initiateStripePayment(this.testOrderId, this.testUserId);
            
            console.log(`✅ Paiement initié avec succès:`);
            console.log(`   Session ID: ${result.sessionId}`);
            console.log(`   URL: ${result.url}`);
            
            return result;
        } catch (error) {
            console.log(`❌ Erreur initiation paiement: ${error.message}`);
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
        console.log('🚀 TEST DE CRÉATION DE COMMANDE');
        console.log('==============================');
        console.log('');
        
        try {
            const userCreated = await this.createTestUser();
            if (userCreated) {
                const variants = await this.getTestVariants();
                if (variants) {
                    const orderCreated = await this.createOrderViaAPI(variants);
                    if (orderCreated) {
                        await this.verifyOrder();
                        await this.testPaymentInitiation();
                    }
                }
            }
            
            console.log('');
            console.log('🎉 TESTS TERMINÉS');
            console.log('================');
            console.log('💡 Si tous les tests sont passés, la création de commande fonctionne.');
            
        } catch (error) {
            console.error('❌ Erreur lors des tests:', error);
        } finally {
            await this.cleanup();
        }
    }
}

// Exécution du script
if (require.main === module) {
    const test = new OrderCreationTest();
    test.runAllTests().catch(console.error);
}

module.exports = OrderCreationTest; 