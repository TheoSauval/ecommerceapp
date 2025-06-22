// Script de test pour la suppression d'utilisateur
const userService = require('./services/userService');
const { supabase } = require('./config/supabase');

async function createTestData() {
    console.log('📦 Création des données de test...');
    
    try {
        // 1. Créer un vendeur de test
        const { data: vendor, error: vendorError } = await supabase
            .from('vendors')
            .insert([{
                nom: 'Vendeur Test',
                user_id: null // Pas de user_id pour ce test
            }])
            .select()
            .single();
        
        if (vendorError) throw vendorError;
        console.log(`✅ Vendeur créé: ${vendor.nom}`);

        // 2. Créer un produit de test
        const { data: product, error: productError } = await supabase
            .from('products')
            .insert([{
                nom: 'Produit Test',
                prix_base: 29.99,
                vendeur_id: vendor.id,
                description: 'Produit de test pour la suppression',
                categorie: 'Test',
                marque: 'TestBrand'
            }])
            .select()
            .single();
        
        if (productError) throw productError;
        console.log(`✅ Produit créé: ${product.nom}`);

        // 3. Créer une couleur de test (si elle n'existe pas)
        let colorId;
        const { data: existingColor } = await supabase
            .from('colors')
            .select('id')
            .eq('nom', 'Rouge')
            .single();
        
        if (existingColor) {
            colorId = existingColor.id;
        } else {
            const { data: color, error: colorError } = await supabase
                .from('colors')
                .insert([{
                    nom: 'Rouge',
                    code_hex: '#FF0000'
                }])
                .select()
                .single();
            
            if (colorError) throw colorError;
            colorId = color.id;
        }
        console.log(`✅ Couleur utilisée: Rouge (ID: ${colorId})`);

        // 4. Créer une taille de test (si elle n'existe pas)
        let heightId;
        const { data: existingHeight } = await supabase
            .from('heights')
            .select('id')
            .eq('nom', 'M')
            .single();
        
        if (existingHeight) {
            heightId = existingHeight.id;
        } else {
            const { data: height, error: heightError } = await supabase
                .from('heights')
                .insert([{
                    nom: 'M',
                    ordre: 3
                }])
                .select()
                .single();
            
            if (heightError) throw heightError;
            heightId = height.id;
        }
        console.log(`✅ Taille utilisée: M (ID: ${heightId})`);

        // 5. Créer une variante de test
        const { data: variant, error: variantError } = await supabase
            .from('product_variants')
            .insert([{
                product_id: product.id,
                color_id: colorId,
                height_id: heightId,
                stock: 10,
                prix: 29.99
            }])
            .select()
            .single();
        
        if (variantError) throw variantError;
        console.log(`✅ Variante créée: ID ${variant.id}`);

        return {
            vendorId: vendor.id,
            productId: product.id,
            variantId: variant.id,
            colorId,
            heightId
        };

    } catch (error) {
        console.error('❌ Erreur création données de test:', error);
        throw error;
    }
}

async function cleanupTestData(testData) {
    console.log('\n🧹 Nettoyage des données de test...');
    
    try {
        // Supprimer dans l'ordre inverse des dépendances
        await supabase.from('product_variants').delete().eq('id', testData.variantId);
        await supabase.from('products').delete().eq('id', testData.productId);
        await supabase.from('vendors').delete().eq('id', testData.vendorId);
        
        console.log('✅ Données de test nettoyées');
    } catch (error) {
        console.error('⚠️ Erreur nettoyage:', error.message);
    }
}

async function testUserDeletion() {
    console.log('🧪 Test de suppression d\'utilisateur...\n');

    let testData;
    
    try {
        // 1. Créer les données de test nécessaires
        testData = await createTestData();

        // 2. Créer un utilisateur de test
        console.log('\n1. Création d\'un utilisateur de test...');
        const testUser = {
            email: `test-deletion-${Date.now()}@example.com`,
            password: 'testpassword123',
            user_metadata: {
                nom: 'Test',
                prenom: 'Deletion',
                age: 25
            }
        };

        const { data: authData, error: authError } = await supabase.auth.admin.createUser(testUser);
        if (authError) throw authError;

        const userId = authData.user.id;
        console.log(`✅ Utilisateur créé avec l'ID: ${userId}`);

        // 3. Ajouter des données de test
        console.log('\n2. Ajout de données de test...');
        
        // Ajouter au panier
        const { error: cartError } = await supabase
            .from('cart_items')
            .insert([{
                user_id: userId,
                variant_id: testData.variantId,
                quantity: 2
            }]);
        if (cartError) console.log('⚠️ Erreur ajout panier:', cartError.message);
        else console.log('✅ Élément ajouté au panier');

        // Ajouter aux favoris
        const { error: favError } = await supabase
            .from('favorites')
            .insert([{
                user_id: userId,
                product_id: testData.productId
            }]);
        if (favError) console.log('⚠️ Erreur ajout favoris:', favError.message);
        else console.log('✅ Produit ajouté aux favoris');

        // Ajouter une notification
        const { error: notifError } = await supabase
            .from('notifications')
            .insert([{
                user_id: userId,
                titre: 'Test notification',
                message: 'Ceci est un test'
            }]);
        if (notifError) console.log('⚠️ Erreur ajout notification:', notifError.message);
        else console.log('✅ Notification ajoutée');

        console.log('✅ Données de test ajoutées');

        // 4. Vérifier que les données existent
        console.log('\n3. Vérification des données avant suppression...');
        
        const { data: profileBefore } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();
        console.log(`📋 Profil: ${profileBefore ? 'Existe' : 'N\'existe pas'}`);

        const { data: cartBefore } = await supabase
            .from('cart_items')
            .select('*')
            .eq('user_id', userId);
        console.log(`🛒 Panier: ${cartBefore?.length || 0} éléments`);

        const { data: favsBefore } = await supabase
            .from('favorites')
            .select('*')
            .eq('user_id', userId);
        console.log(`❤️ Favoris: ${favsBefore?.length || 0} éléments`);

        const { data: notifsBefore } = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', userId);
        console.log(`🔔 Notifications: ${notifsBefore?.length || 0} éléments`);

        // 5. Supprimer l'utilisateur
        console.log('\n4. Suppression de l\'utilisateur...');
        await userService.deleteProfile(userId);
        console.log('✅ Suppression terminée');

        // 6. Vérifier que les données ont été supprimées
        console.log('\n5. Vérification des données après suppression...');
        
        const { data: profileAfter } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();
        console.log(`📋 Profil: ${profileAfter ? 'Existe encore' : 'Supprimé'}`);

        const { data: cartAfter } = await supabase
            .from('cart_items')
            .select('*')
            .eq('user_id', userId);
        console.log(`🛒 Panier: ${cartAfter?.length || 0} éléments restants`);

        const { data: favsAfter } = await supabase
            .from('favorites')
            .select('*')
            .eq('user_id', userId);
        console.log(`❤️ Favoris: ${favsAfter?.length || 0} éléments restants`);

        const { data: notifsAfter } = await supabase
            .from('notifications')
            .select('*')
            .eq('user_id', userId);
        console.log(`🔔 Notifications: ${notifsAfter?.length || 0} éléments restants`);

        // 7. Vérifier si l'utilisateur existe encore dans auth.users
        const userExists = await userService.checkUserExists(userId);
        console.log(`👤 Utilisateur dans auth.users: ${userExists ? 'Existe encore' : 'Supprimé'}`);

        console.log('\n✅ Test terminé avec succès !');

    } catch (error) {
        console.error('❌ Erreur lors du test:', error);
    } finally {
        // Nettoyer les données de test
        if (testData) {
            await cleanupTestData(testData);
        }
    }
}

// Exécuter le test si le script est appelé directement
if (require.main === module) {
    testUserDeletion();
}

module.exports = { testUserDeletion, createTestData, cleanupTestData }; 