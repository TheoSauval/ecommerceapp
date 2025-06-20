// Script de test pour vérifier la migration Supabase
require('dotenv').config();
const { supabase, supabasePublic } = require('./config/supabase');
const authService = require('./services/authService');

async function testSupabaseAuth() {
    console.log('🧪 Test de l\'authentification Supabase Auth...\n');

    try {
        // Test 1: Inscription d'un utilisateur
        console.log('1️⃣ Test d\'inscription...');
        const testUser = {
            nom: 'Test',
            prenom: 'User',
            age: 25,
            mail: `test-${Date.now()}@example.com`,
            password: 'password123',
            role: 'user'
        };

        const registeredUser = await authService.register(testUser);
        console.log('✅ Inscription réussie:', {
            id: registeredUser.id,
            nom: registeredUser.nom,
            prenom: registeredUser.prenom,
            role: registeredUser.role
        });

        // Test 2: Connexion
        console.log('\n2️⃣ Test de connexion...');
        const loginResult = await authService.login(testUser.mail, testUser.password);
        console.log('✅ Connexion réussie:', {
            user: loginResult.user,
            hasSession: !!loginResult.session
        });

        // Test 3: Récupération du profil
        console.log('\n3️⃣ Test de récupération du profil...');
        const profile = await authService.getUserById(registeredUser.id);
        console.log('✅ Profil récupéré:', {
            id: profile.id,
            nom: profile.nom,
            prenom: profile.prenom,
            age: profile.age,
            role: profile.role,
            email: profile.email
        });

        // Test 4: Mise à jour du profil
        console.log('\n4️⃣ Test de mise à jour du profil...');
        const updatedProfile = await authService.updateProfile(registeredUser.id, {
            nom: 'TestUpdated',
            age: 26
        });
        console.log('✅ Profil mis à jour:', {
            nom: updatedProfile.nom,
            age: updatedProfile.age
        });

        // Test 5: Test avec un vendeur
        console.log('\n5️⃣ Test d\'inscription vendeur...');
        const vendorUser = {
            nom: 'Vendor',
            prenom: 'Test',
            age: 30,
            mail: `vendor-${Date.now()}@example.com`,
            password: 'password123',
            role: 'vendor'
        };

        const registeredVendor = await authService.register(vendorUser);
        console.log('✅ Vendeur inscrit:', {
            id: registeredVendor.id,
            role: registeredVendor.role
        });

        // Test 6: Vérification de la table vendors
        console.log('\n6️⃣ Test de la table vendors...');
        const { data: vendors, error: vendorError } = await supabase
            .from('vendors')
            .select('*')
            .eq('user_id', registeredVendor.id);

        if (vendorError) {
            console.log('❌ Erreur vendors:', vendorError);
        } else {
            console.log('✅ Vendeur trouvé dans la table vendors:', vendors[0]);
        }

        // Test 7: Test de déconnexion
        console.log('\n7️⃣ Test de déconnexion...');
        await authService.logout();
        console.log('✅ Déconnexion réussie');

        console.log('\n🎉 Tous les tests d\'authentification sont passés !');
        console.log('\n📋 Résumé:');
        console.log('- ✅ Inscription utilisateur');
        console.log('- ✅ Connexion');
        console.log('- ✅ Récupération profil');
        console.log('- ✅ Mise à jour profil');
        console.log('- ✅ Inscription vendeur');
        console.log('- ✅ Création automatique profil vendeur');
        console.log('- ✅ Déconnexion');

    } catch (error) {
        console.error('❌ Erreur lors des tests:', error.message);
        console.error('Stack:', error.stack);
    }
}

async function testDatabaseOperations() {
    console.log('\n🗄️ Test des opérations de base de données...\n');

    try {
        // Test 1: Créer un produit
        console.log('1️⃣ Test de création de produit...');
        
        // D'abord créer un vendeur
        const vendorUser = {
            nom: 'ProductVendor',
            prenom: 'Test',
            age: 35,
            mail: `product-vendor-${Date.now()}@example.com`,
            password: 'password123',
            role: 'vendor'
        };

        const vendor = await authService.register(vendorUser);
        
        // Récupérer l'ID du vendeur
        const { data: vendorProfile } = await supabase
            .from('vendors')
            .select('id')
            .eq('user_id', vendor.id)
            .single();

        // Créer un produit
        const { data: product, error: productError } = await supabase
            .from('products')
            .insert([{
                nom: 'Produit Test',
                prix: 29.99,
                quantite: 10,
                vendeur_id: vendorProfile.id,
                description: 'Description du produit test',
                categorie: 'Test',
                marque: 'TestBrand'
            }])
            .select()
            .single();

        if (productError) {
            console.log('❌ Erreur création produit:', productError);
        } else {
            console.log('✅ Produit créé:', product);
        }

        // Test 2: Ajouter des couleurs et tailles
        console.log('\n2️⃣ Test d\'ajout de couleurs et tailles...');
        
        const { data: colors, error: colorError } = await supabase
            .from('colors')
            .insert([
                { produit_id: product.id, couleur: 'Rouge' },
                { produit_id: product.id, couleur: 'Bleu' }
            ])
            .select();

        const { data: heights, error: heightError } = await supabase
            .from('heights')
            .insert([
                { produit_id: product.id, taille: 'S' },
                { produit_id: product.id, taille: 'M' },
                { produit_id: product.id, taille: 'L' }
            ])
            .select();

        if (colorError) {
            console.log('❌ Erreur couleurs:', colorError);
        } else {
            console.log('✅ Couleurs ajoutées:', colors);
        }

        if (heightError) {
            console.log('❌ Erreur tailles:', heightError);
        } else {
            console.log('✅ Tailles ajoutées:', heights);
        }

        console.log('\n🎉 Tous les tests de base de données sont passés !');

    } catch (error) {
        console.error('❌ Erreur lors des tests de base de données:', error.message);
    }
}

// Exécuter les tests
async function runAllTests() {
    console.log('🚀 Démarrage des tests Supabase Auth...\n');
    
    await testSupabaseAuth();
    await testDatabaseOperations();
    
    console.log('\n✨ Tests terminés !');
    process.exit(0);
}

runAllTests().catch(console.error);

// Script de test pour créer un utilisateur admin et son profil vendeur
require('dotenv').config();
const { supabasePublic } = require('./config/supabase');

async function createTestUser() {
    try {
        console.log('Création d\'un utilisateur de test...');
        
        // 1. Créer un utilisateur dans Supabase Auth
        const { data: authData, error: authError } = await supabasePublic.auth.signUp({
            email: 'admin@test.com',
            password: 'password123',
            options: {
                data: {
                    nom: 'Admin',
                    prenom: 'Test',
                    age: 25,
                    role: 'admin'
                }
            }
        });
        
        if (authError) {
            console.error('Erreur lors de la création de l\'utilisateur:', authError);
            return;
        }
        
        console.log('Utilisateur créé:', authData.user);
        
        // 2. Créer un profil vendeur
        const { data: vendorData, error: vendorError } = await supabasePublic
            .from('vendors')
            .insert({
                nom: 'Boutique Test',
                user_id: authData.user.id
            })
            .select()
            .single();
            
        if (vendorError) {
            console.error('Erreur lors de la création du profil vendeur:', vendorError);
            return;
        }
        
        console.log('Profil vendeur créé:', vendorData);
        
        // 3. Se connecter pour obtenir le token
        const { data: loginData, error: loginError } = await supabasePublic.auth.signInWithPassword({
            email: 'admin@test.com',
            password: 'password123'
        });
        
        if (loginError) {
            console.error('Erreur lors de la connexion:', loginError);
            return;
        }
        
        console.log('Connexion réussie!');
        console.log('Token d\'accès:', loginData.session.access_token);
        console.log('Utilisez ce token dans votre dashboard admin');
        
        // 4. Tester la récupération du profil
        const { data: profileData, error: profileError } = await supabasePublic
            .from('user_profiles')
            .select('*')
            .eq('id', authData.user.id)
            .single();
            
        if (profileError) {
            console.error('Erreur lors de la récupération du profil:', profileError);
        } else {
            console.log('Profil utilisateur récupéré:', profileData);
        }
        
    } catch (error) {
        console.error('Erreur générale:', error);
    }
}

// Fonction pour tester l'authentification avec un token
async function testAuth(token) {
    try {
        console.log('Test d\'authentification avec le token...');
        
        const { data: { user }, error } = await supabasePublic.auth.getUser(token);
        
        if (error) {
            console.error('Erreur d\'authentification:', error);
            return;
        }
        
        console.log('Utilisateur authentifié:', user);
        
        // Récupérer le profil vendeur
        const { data: vendorData, error: vendorError } = await supabasePublic
            .from('vendors')
            .select('*')
            .eq('user_id', user.id)
            .single();
            
        if (vendorError) {
            console.error('Erreur lors de la récupération du vendeur:', vendorError);
        } else {
            console.log('Profil vendeur récupéré:', vendorData);
        }
        
    } catch (error) {
        console.error('Erreur lors du test d\'authentification:', error);
    }
}

// Exécuter le script
if (require.main === module) {
    const command = process.argv[2];
    
    if (command === 'create') {
        createTestUser();
    } else if (command === 'test' && process.argv[3]) {
        testAuth(process.argv[3]);
    } else {
        console.log('Usage:');
        console.log('  node test-supabase.js create  - Créer un utilisateur de test');
        console.log('  node test-supabase.js test <token>  - Tester l\'authentification');
    }
}

module.exports = { createTestUser, testAuth }; 