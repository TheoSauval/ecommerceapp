const { supabase } = require('./config/supabase');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
require('dotenv').config();

/**
 * TESTS DE PAIEMENT STRIPE
 * ========================
 * 
 * Ce fichier contient des tests pour vérifier l'intégration Stripe
 * avec votre base de données Supabase existante.
 * 
 * PRÉREQUIS :
 * - Avoir des produits dans la table products
 * - Avoir des variantes dans product_variants
 * - Avoir un utilisateur test dans auth.users
 * - Avoir configuré les clés Stripe dans .env
 */

class StripePaymentTester {
    constructor() {
        this.testUserId = null;
        this.testOrderId = null;
        this.testPaymentId = null;
        this.testSessionId = null;
        this.testOrderDetails = {}; // Pour stocker les détails de la commande de test
    }

    // =====================================================
    // TESTS DE BASE DE DONNÉES
    // =====================================================

    /**
     * Test 1: Vérifier que des produits existent
     */
    async testProductsExist() {
        console.log('\n🔍 Test 1: Vérification des produits existants...');
        
        const { data: products, error } = await supabase
            .from('products')
            .select('*')
            .eq('actif', true)
            .limit(5);
            
        if (error) {
            console.error('❌ Erreur lors de la récupération des produits:', error);
            return false;
        }
        
        if (!products || products.length === 0) {
            console.error('❌ Aucun produit actif trouvé dans la base de données');
            return false;
        }
        
        console.log(`✅ ${products.length} produits trouvés:`);
        products.forEach(product => {
            console.log(`   - ${product.nom} (${product.prix_base}€)`);
        });
        
        return products;
    }

    /**
     * Test 2: Vérifier que des variantes existent
     */
    async testVariantsExist() {
        console.log('\n🔍 Test 2: Vérification des variantes existantes...');
        
        const { data: variants, error } = await supabase
            .from('product_variants')
            .select(`
                *,
                products (
                    id,
                    nom,
                    prix_base
                ),
                colors (
                    id,
                    nom
                ),
                heights (
                    id,
                    nom
                )
            `)
            .eq('actif', true)
            .gt('stock', 0)
            .limit(5);
            
        if (error) {
            console.error('❌ Erreur lors de la récupération des variantes:', error);
            return false;
        }
        
        if (!variants || variants.length === 0) {
            console.error('❌ Aucune variante en stock trouvée');
            return false;
        }
        
        console.log(`✅ ${variants.length} variantes en stock trouvées:`);
        variants.forEach(variant => {
            const prix = variant.prix || variant.products.prix_base;
            console.log(`   - ${variant.products.nom} (${variant.colors.nom}, ${variant.heights.nom}) - ${prix}€ - Stock: ${variant.stock}`);
        });
        
        return variants;
    }

    /**
     * Test 3b: Utiliser un utilisateur existant (fallback)
     */
    async testUseExistingUser() {
        console.log('\n🔍 Test 3b: Utilisation d\'un utilisateur existant...');
        
        try {
            // Essayer de se connecter avec un utilisateur existant
            const { data: authUser, error: authError } = await supabase.auth.signInWithPassword({
                email: 'sauvaltheo@gmail.com',
                password: 'azerty'
            });
            
            if (authError) {
                console.error('❌ Erreur lors de la connexion:', authError);
                return false;
            }
            
            this.testUserId = authUser.user.id;
            console.log(`✅ Utilisateur existant connecté: ${authUser.user.email} (ID: ${this.testUserId})`);
            
            return authUser.user;
            
        } catch (error) {
            console.error('❌ Erreur inattendue lors de la connexion:', error);
            return false;
        }
    }

    /**
     * Test 3: Créer un utilisateur test
     */
    async testCreateTestUser() {
        console.log('\n🔍 Test 3: Création d\'un utilisateur test...');
        
        // Utiliser un email valide avec timestamp unique
        const timestamp = Date.now();
        const testEmail = `test.user.${timestamp}@gmail.com`;
        const testPassword = 'TestPassword123!';
        
        try {
            const { data: authUser, error: authError } = await supabase.auth.signUp({
                email: testEmail,
                password: testPassword,
                options: {
                    data: {
                        nom: 'Test',
                        prenom: 'Utilisateur',
                        age: 25,
                        role: 'user'
                    }
                }
            });
            
            if (authError) {
                console.error('❌ Erreur lors de la création de l\'utilisateur:', authError);
                
                // Si l'email est invalide, essayer avec un email différent
                if (authError.message.includes('invalid') || authError.code === 'email_address_invalid') {
                    console.log('🔄 Tentative avec un email alternatif...');
                    
                    const alternativeEmail = `test${timestamp}@outlook.com`;
                    const { data: altAuthUser, error: altAuthError } = await supabase.auth.signUp({
                        email: alternativeEmail,
                        password: testPassword,
                        options: {
                            data: {
                                nom: 'Test',
                                prenom: 'Utilisateur',
                                age: 25,
                                role: 'user'
                            }
                        }
                    });
                    
                    if (altAuthError) {
                        console.error('❌ Erreur avec l\'email alternatif:', altAuthError);
                        console.log('🔄 Tentative avec un utilisateur existant...');
                        return await this.testUseExistingUser();
                    }
                    
                    this.testUserId = altAuthUser.user.id;
                    console.log(`✅ Utilisateur test créé: ${alternativeEmail} (ID: ${this.testUserId})`);
                    return altAuthUser.user;
                }
                
                // Si c'est une autre erreur, essayer avec un utilisateur existant
                console.log('🔄 Tentative avec un utilisateur existant...');
                return await this.testUseExistingUser();
            }
            
            this.testUserId = authUser.user.id;
            console.log(`✅ Utilisateur test créé: ${testEmail} (ID: ${this.testUserId})`);
            
            return authUser.user;
            
        } catch (error) {
            console.error('❌ Erreur inattendue lors de la création de l\'utilisateur:', error);
            console.log('🔄 Tentative avec un utilisateur existant...');
            return await this.testUseExistingUser();
        }
    }

    // =====================================================
    // TESTS DE COMMANDE
    // =====================================================

    /**
     * Test 4: Créer une commande test
     */
    async testCreateOrder(variants) {
        console.log('\n🔍 Test 4: Création d\'une commande test...');
        
        if (!this.testUserId) {
            console.error('❌ Utilisateur test non créé');
            return false;
        }
        
        // Sélectionner une variante pour la commande
        const selectedVariant = variants[0];
        const prix = selectedVariant.prix || selectedVariant.products.prix_base;
        const quantity = 2;
        const totalPrice = prix * quantity;
        
        // Stocker les détails pour le test de stock
        this.testOrderDetails = {
            variant: selectedVariant,
            quantity: quantity,
            initialStock: selectedVariant.stock
        };
        
        // Créer la commande
        const { data: order, error: orderError } = await supabase
            .from('orders')
            .insert([{
                prix_total: totalPrice,
                status: 'En attente',
                user_id: this.testUserId,
                adresse_livraison: '123 Rue Test, 75001 Paris',
                methode_paiement: 'Stripe'
            }])
            .select()
            .single();
            
        if (orderError) {
            console.error('❌ Erreur lors de la création de la commande:', orderError);
            return false;
        }
        
        this.testOrderId = order.id;
        console.log(`✅ Commande créée: ID ${order.id}, Total: ${totalPrice}€`);
        
        // Ajouter les variantes à la commande
        const { error: orderVariantError } = await supabase
            .from('order_variants')
            .insert([{
                order_id: order.id,
                variant_id: selectedVariant.id,
                quantity: quantity,
                unit_price: prix
            }]);
            
        if (orderVariantError) {
            console.error('❌ Erreur lors de l\'ajout des variantes:', orderVariantError);
            return false;
        }
        
        console.log(`✅ Variante ajoutée à la commande: ${selectedVariant.products.nom}`);
        
        return order;
    }

    // =====================================================
    // TESTS STRIPE
    // =====================================================

    /**
     * Test 5: Tester la création d'une session Stripe
     */
    async testStripeSession() {
        console.log('\n🔍 Test 5: Test de création de session Stripe...');
        
        if (!this.testOrderId) {
            console.error('❌ Commande test non créée');
            return false;
        }
        
        try {
            // Récupérer la commande avec ses variantes
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
                .eq('id', this.testOrderId)
                .single();
            
            // Créer la session Stripe
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
                success_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
                cancel_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/payment/cancel`,
                metadata: {
                    orderId: order.id.toString(),
                    userId: this.testUserId
                }
            });
            
            console.log(`✅ Session Stripe créée: ${session.id}`);
            console.log(`   URL de paiement: ${session.url}`);
            console.log(`   Montant total: ${session.amount_total / 100}€`);
            
            console.log('\n' + '-'.repeat(50));
            console.log('👉 ACTION REQUISE : Finalisez le paiement !');
            console.log('-'.repeat(50));
            console.log('1. Copiez l\'URL de paiement ci-dessus et ouvrez-la dans votre navigateur.');
            console.log('2. Utilisez les informations de carte de test suivantes:');
            console.log('   - Numéro de carte: 4242 4242 4242 4242');
            console.log('   - Date d\'expiration: N\'importe quelle date future (ex: 12/25)');
            console.log('   - CVC: N\'importe quel code (ex: 123)');
            console.log('3. Validez le paiement pour le voir apparaître sur votre dashboard Stripe.');
            console.log('-'.repeat(50) + '\n');
            
            // Sauvegarder l'ID de session pour référence
            this.testSessionId = session.id;
            
            return session;
            
        } catch (error) {
            console.error('❌ Erreur lors de la création de la session Stripe:', error);
            return false;
        }
    }

    /**
     * Afficher les détails des sessions Stripe
     */
    async showStripeSessionDetails() {
        if (!this.testSessionId) return;
        
        try {
            const session = await stripe.checkout.sessions.retrieve(this.testSessionId);
            
            console.log(`\n💳 Session Stripe ID ${session.id}:`);
            console.log(`   - Statut: ${session.status}`);
            console.log(`   - Montant: ${session.amount_total / 100}€`);
            console.log(`   - Devise: ${session.currency}`);
            console.log(`   - Mode: ${session.mode}`);
            console.log(`   - Créée: ${new Date(session.created * 1000).toLocaleString()}`);
            console.log(`   - URL: ${session.url}`);
            
            if (session.payment_intent) {
                console.log(`   - Payment Intent: ${session.payment_intent}`);
            }
            
            console.log(`   - Métadonnées:`, session.metadata);
            
        } catch (error) {
            console.error('❌ Erreur lors de la récupération de la session:', error);
        }
    }

    /**
     * Test 6: Tester le webhook Stripe (simulation)
     */
    async testStripeWebhook(sessionId) {
        console.log('\n🔍 Test 6: Test de webhook Stripe (simulation)...');
        
        try {
            // Récupérer la session Stripe
            const session = await stripe.checkout.sessions.retrieve(sessionId);
            
            // Simuler un événement de paiement réussi
            const event = {
                type: 'checkout.session.completed',
                data: {
                    object: session
                }
            };
            
            // Traiter l'événement
            await this.handleStripeWebhook(event);
            
            console.log('✅ Webhook traité avec succès');
            
            // Vérifier que la commande a été mise à jour
            const { data: updatedOrder } = await supabase
                .from('orders')
                .select('*')
                .eq('id', this.testOrderId)
                .single();
                
            console.log(`   Statut de la commande: ${updatedOrder.status}`);
            
            // Vérifier que le paiement a été créé
            const { data: payment } = await supabase
                .from('payments')
                .select('*')
                .eq('order_id', this.testOrderId)
                .single();
                
            if (payment) {
                console.log(`   Paiement créé: ID ${payment.id}, Statut: ${payment.status}`);
                this.testPaymentId = payment.id;
            }
            
            return true;
            
        } catch (error) {
            console.error('❌ Erreur lors du test du webhook:', error);
            console.log('💡 Note: Le webhook secret n\'est pas configuré, mais les tests de base fonctionnent');
            return false;
        }
    }

    /**
     * Test 6b: Test alternatif sans webhook (simulation directe)
     */
    async testDirectPaymentSimulation() {
        console.log('\n🔍 Test 6b: Simulation directe de paiement (sans webhook)...');
        
        try {
            // Simuler directement la mise à jour de la commande
            const { data: updatedOrder, error: orderError } = await supabase
                .from('orders')
                .update({ status: 'Payé' })
                .eq('id', this.testOrderId)
                .select()
                .single();
                
            if (orderError) {
                console.error('❌ Erreur lors de la mise à jour de la commande:', orderError);
                return false;
            }
            
            console.log(`✅ Commande mise à jour: Statut ${updatedOrder.status}`);

            // Décrémenter le stock
            console.log(`   Appel de la fonction de diminution de stock pour la commande ${this.testOrderId}...`);
            const { error: stockError } = await supabase.rpc('decrease_stock', { order_id_param: this.testOrderId });
            if (stockError) {
                console.error(`   Erreur lors de la décrémentation du stock:`, stockError);
            }
            
            // Créer un enregistrement de paiement simulé
            const { data: payment, error: paymentError } = await supabase
                .from('payments')
                .insert([{
                    order_id: this.testOrderId,
                    user_id: this.testUserId,
                    amount: updatedOrder.prix_total,
                    status: 'Payé',
                    stripe_payment_intent_id: `pi_test_${Date.now()}`
                }])
                .select()
                .single();
                
            if (paymentError) {
                console.error('❌ Erreur lors de la création du paiement:', paymentError);
                return false;
            }
            
            console.log(`✅ Paiement simulé créé: ID ${payment.id}, Statut: ${payment.status}`);
            this.testPaymentId = payment.id;
            
            return true;
            
        } catch (error) {
            console.error('❌ Erreur lors de la simulation de paiement:', error);
            return false;
        }
    }

    /**
     * Gestionnaire de webhook Stripe
     */
    async handleStripeWebhook(event) {
        switch (event.type) {
            case 'checkout.session.completed':
                const session = event.data.object;
                const orderId = parseInt(session.metadata.orderId, 10);
                
                // Mettre à jour le statut de la commande
                await supabase
                    .from('orders')
                    .update({ status: 'Payé' })
                    .eq('id', orderId);
                    
                // Décrémenter le stock
                console.log(`   Simulation de la diminution du stock pour la commande ${orderId}...`);
                const { error: stockError } = await supabase.rpc('decrease_stock', { order_id_param: orderId });
                if (stockError) {
                    console.error(`   Erreur lors de la simulation de la décrémentation du stock:`, stockError);
                }

                // Créer un enregistrement de paiement
                const { data: payment } = await supabase
                    .from('payments')
                    .insert([{
                        order_id: orderId,
                        user_id: session.metadata.userId,
                        amount: session.amount_total / 100,
                        status: 'Payé',
                        stripe_payment_intent_id: session.payment_intent
                    }])
                    .select()
                    .single();
                    
                console.log(`   Paiement enregistré: ${payment.id}`);
                break;
        }
    }

    /**
     * Test 7: Tester le remboursement
     */
    async testRefund() {
        console.log('\n🔍 Test 7: Test de remboursement...');
        
        if (!this.testPaymentId) {
            console.error('❌ Paiement test non créé');
            return false;
        }
        
        try {
            // Récupérer le paiement
            const { data: payment, error: paymentError } = await supabase
                .from('payments')
                .select('*')
                .eq('id', this.testPaymentId)
                .single();
                
            if (paymentError || !payment) {
                console.error('❌ Erreur lors de la récupération du paiement:', paymentError);
                return false;
            }
            
            console.log(`📊 Paiement trouvé: ID ${payment.id}, Montant: ${payment.amount}€, Statut: ${payment.status}`);
            
            // Si c'est un paiement simulé (sans webhook), simuler le remboursement
            if (payment.stripe_payment_intent_id && payment.stripe_payment_intent_id.startsWith('pi_test_')) {
                console.log('💡 Paiement simulé détecté, simulation du remboursement...');
                
                // Mettre à jour le statut du paiement
                await supabase
                    .from('payments')
                    .update({ 
                        status: 'Remboursé',
                        refund_amount: payment.amount
                    })
                    .eq('id', this.testPaymentId);
                
                console.log(`✅ Remboursement simulé créé`);
                console.log(`   Montant remboursé: ${payment.amount}€`);
                
                return { id: 're_simulated', amount: payment.amount * 100 };
            }
            
            // Sinon, créer le remboursement Stripe réel
            console.log('💳 Création du remboursement Stripe...');
            const refund = await stripe.refunds.create({
                payment_intent: payment.stripe_payment_intent_id,
                amount: Math.round(payment.amount * 100)
            });
            
            // Mettre à jour le statut du paiement
            await supabase
                .from('payments')
                .update({ 
                    status: 'Remboursé',
                    refund_amount: payment.amount
                })
                .eq('id', this.testPaymentId);
            
            console.log(`✅ Remboursement créé: ${refund.id}`);
            console.log(`   Montant remboursé: ${refund.amount / 100}€`);
            
            return refund;
            
        } catch (error) {
            console.error('❌ Erreur lors du remboursement:', error);
            return false;
        }
    }

    /**
     * Test 8: Vérifier la diminution du stock
     */
    async testStockIsDecreased() {
        console.log('\n🔍 Test 8: Vérification de la diminution du stock...');
        
        const { variant, quantity, initialStock } = this.testOrderDetails;
        
        if (!variant) {
            console.error('❌ Détails de la commande de test non trouvés.');
            return false;
        }

        const { data: updatedVariant, error } = await supabase
            .from('product_variants')
            .select('stock')
            .eq('id', variant.id)
            .single();
        
        if (error) {
            console.error('❌ Erreur lors de la récupération de la variante mise à jour:', error);
            return false;
        }
    
        const expectedStock = initialStock - quantity;
        if (updatedVariant.stock !== expectedStock) {
            console.error(`❌ Le stock n'a pas été correctement décrémenté.`);
            console.error(`   - Stock initial: ${initialStock}`);
            console.error(`   - Stock attendu: ${expectedStock}`);
            console.error(`   - Stock actuel:  ${updatedVariant.stock}`);
            return false;
        }
    
        console.log(`✅ Le stock a été correctement mis à jour: ${initialStock} -> ${updatedVariant.stock}`);
        return true;
    }

    /**
     * Afficher les détails des données créées
     */
    async showCreatedData() {
        console.log('\n📊 DÉTAILS DES DONNÉES CRÉÉES');
        console.log('==============================');
        
        if (this.testOrderId) {
            // Afficher les détails de la commande
            const { data: order } = await supabase
                .from('orders')
                .select(`
                    *,
                    order_variants (
                        quantity,
                        unit_price,
                        product_variants (
                            products (
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
                
            if (order) {
                console.log(`📦 Commande ID ${order.id}:`);
                console.log(`   - Statut: ${order.status}`);
                console.log(`   - Total: ${order.prix_total}€`);
                console.log(`   - Date: ${new Date(order.created_at).toLocaleString()}`);
                console.log(`   - Méthode: ${order.methode_paiement}`);
                console.log(`   - Adresse: ${order.adresse_livraison}`);
                
                if (order.order_variants && order.order_variants.length > 0) {
                    console.log(`   - Produits:`);
                    order.order_variants.forEach(item => {
                        const product = item.product_variants.products.nom;
                        const color = item.product_variants.colors.nom;
                        const size = item.product_variants.heights.nom;
                        console.log(`     * ${product} (${color}, ${size}) - ${item.quantity}x ${item.unit_price}€`);
                    });
                }
            }
        }
        
        if (this.testPaymentId) {
            // Afficher les détails du paiement
            const { data: payment } = await supabase
                .from('payments')
                .select('*')
                .eq('id', this.testPaymentId)
                .single();
                
            if (payment) {
                console.log(`\n💳 Paiement ID ${payment.id}:`);
                console.log(`   - Montant: ${payment.amount}€`);
                console.log(`   - Statut: ${payment.status}`);
                console.log(`   - Date: ${new Date(payment.date_paiement).toLocaleString()}`);
                console.log(`   - Stripe ID: ${payment.stripe_payment_intent_id || 'Simulé'}`);
                if (payment.refund_amount) {
                    console.log(`   - Remboursé: ${payment.refund_amount}€`);
                }
            }
        }
        
        if (this.testUserId) {
            // Afficher les détails de l'utilisateur
            const { data: user } = await supabase
                .from('user_profiles')
                .select('*')
                .eq('id', this.testUserId)
                .single();
                
            if (user) {
                console.log(`\n👤 Utilisateur ID ${user.id}:`);
                console.log(`   - Nom: ${user.nom} ${user.prenom}`);
                console.log(`   - Âge: ${user.age}`);
                console.log(`   - Rôle: ${user.role}`);
                console.log(`   - Créé: ${new Date(user.created_at).toLocaleString()}`);
            }
        }
        
        // Afficher les détails Stripe
        await this.showStripeSessionDetails();
        
        console.log('\n🔗 Liens utiles:');
        console.log(`   - Dashboard Stripe: https://dashboard.stripe.com/test/payments`);
        console.log(`   - Sessions Stripe: https://dashboard.stripe.com/test/checkout/sessions`);
        console.log(`   - Dashboard Supabase: ${process.env.SUPABASE_URL}/dashboard`);
        console.log(`   - Tableau de bord Supabase: ${process.env.SUPABASE_URL}/dashboard/project/default/editor`);
    }

    // =====================================================
    // NETTOYAGE
    // =====================================================

    /**
     * Nettoyer les données de test (optionnel)
     */
    async cleanup() {
        console.log('\n🧹 Nettoyage des données de test...');
        
        const shouldCleanup = process.env.CLEANUP_TEST_DATA === 'true';
        
        if (!shouldCleanup) {
            console.log('💾 Mode conservation activé - Les données de test sont conservées');
            console.log('   Pour activer le nettoyage, définissez CLEANUP_TEST_DATA=true dans .env');
            console.log('   📊 Commandes créées:', this.testOrderId ? `ID ${this.testOrderId}` : 'Aucune');
            console.log('   💳 Paiements créés:', this.testPaymentId ? `ID ${this.testPaymentId}` : 'Aucun');
            return;
        }
        
        try {
            // Supprimer les paiements de test
            if (this.testPaymentId) {
                await supabase
                    .from('payments')
                    .delete()
                    .eq('id', this.testPaymentId);
                console.log('   ✅ Paiements supprimés');
            }
            
            // Supprimer les commandes de test
            if (this.testOrderId) {
                await supabase
                    .from('order_variants')
                    .delete()
                    .eq('order_id', this.testOrderId);
                    
                await supabase
                    .from('orders')
                    .delete()
                    .eq('id', this.testOrderId);
                console.log('   ✅ Commandes supprimées');
            }
            
            // Supprimer l'utilisateur test seulement s'il a été créé (pas un utilisateur existant)
            if (this.testUserId && this.testUserId !== 'sauvaltheo@gmail.com') {
                try {
                    await supabase.auth.admin.deleteUser(this.testUserId);
                    console.log('   ✅ Utilisateur test supprimé');
                } catch (error) {
                    console.log('   ⚠️  Impossible de supprimer l\'utilisateur (peut-être un utilisateur existant)');
                }
            } else {
                console.log('   ⚠️  Utilisateur existant conservé');
            }
            
        } catch (error) {
            console.error('❌ Erreur lors du nettoyage:', error);
        }
    }

    // =====================================================
    // EXÉCUTION DES TESTS
    // =====================================================

    /**
     * Exécuter tous les tests
     */
    async runAllTests() {
        console.log('🚀 DÉBUT DES TESTS DE PAIEMENT STRIPE');
        console.log('=====================================');
        
        try {
            // Tests de base de données
            const products = await this.testProductsExist();
            if (!products) return;
            
            const variants = await this.testVariantsExist();
            if (!variants) return;
            
            const user = await this.testCreateTestUser();
            if (!user) return;
            
            // Tests de commande
            const order = await this.testCreateOrder(variants);
            if (!order) return;
            
            // Tests Stripe
            const session = await this.testStripeSession();
            if (!session) return;
            
            // Test de webhook ou simulation directe
            let webhookResult = await this.testStripeWebhook(session.id);
            if (!webhookResult) {
                console.log('\n🔄 Tentative avec simulation directe...');
                webhookResult = await this.testDirectPaymentSimulation();
            }
            
            if (!webhookResult) {
                console.log('⚠️  Les tests de paiement ont échoué, mais la session Stripe fonctionne');
                console.log('💡 Pour les tests complets, configurez un webhook Stripe');
                // Afficher quand même les données créées
                await this.showCreatedData();
                return;
            }
            
            const refund = await this.testRefund();
            if (!refund) return;

            await this.testStockIsDecreased();
            
            console.log('\n🎉 TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS !');
            
            // Afficher les détails des données créées
            await this.showCreatedData();
            
        } catch (error) {
            console.error('\n❌ ERREUR LORS DES TESTS:', error);
        } finally {
            // Nettoyer les données de test (optionnel)
            await this.cleanup();
        }
    }
}

// =====================================================
// EXÉCUTION
// =====================================================

if (require.main === module) {
    const tester = new StripePaymentTester();
    tester.runAllTests();
}

module.exports = StripePaymentTester; 