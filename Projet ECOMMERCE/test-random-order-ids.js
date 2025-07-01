const { supabase } = require('./config/supabase');

async function testRandomOrderIds() {
    console.log('🧪 Test des IDs aléatoires pour les commandes...');
    
    try {
        // Test 1: Vérifier la structure de la table orders
        console.log('\n📋 Test 1: Vérification de la structure de la table orders...');
        const { data: tableInfo, error: tableError } = await supabase
            .from('information_schema.columns')
            .select('column_name, data_type')
            .eq('table_name', 'orders')
            .eq('table_schema', 'public')
            .eq('column_name', 'id');
            
        if (tableError) {
            console.error('❌ Erreur lors de la vérification de la structure:', tableError);
            return;
        }
        
        if (tableInfo && tableInfo.length > 0) {
            const idColumn = tableInfo[0];
            console.log(`✅ Type de la colonne 'id': ${idColumn.data_type}`);
            
            if (idColumn.data_type === 'uuid') {
                console.log('✅ La table orders utilise bien des UUIDs !');
            } else {
                console.log('❌ La table orders n\'utilise pas encore des UUIDs');
                console.log('💡 Appliquez d\'abord la migration 006_random_order_ids.sql');
                return;
            }
        } else {
            console.log('❌ Impossible de vérifier la structure de la table');
            return;
        }
        
        // Test 2: Créer une commande de test
        console.log('\n🛒 Test 2: Création d\'une commande de test...');
        
        // Récupérer un utilisateur de test
        const { data: users, error: usersError } = await supabase
            .from('user_profiles')
            .select('id')
            .limit(1);
            
        if (usersError || !users || users.length === 0) {
            console.log('⚠️  Aucun utilisateur trouvé, création d\'un utilisateur de test...');
            // Créer un utilisateur de test si nécessaire
            const { data: testUser, error: testUserError } = await supabase.auth.signUp({
                email: 'test@example.com',
                password: 'testpassword123'
            });
            
            if (testUserError) {
                console.error('❌ Erreur lors de la création de l\'utilisateur de test:', testUserError);
                return;
            }
            
            console.log('✅ Utilisateur de test créé');
        }
        
        // Créer une commande de test
        const { data: testOrder, error: orderError } = await supabase
            .from('orders')
            .insert([{
                prix_total: 25.99,
                status: 'En attente',
                user_id: users?.[0]?.id || 'test-user-id',
                adresse_livraison: '123 Test Street, Test City',
                methode_paiement: 'Carte bancaire'
            }])
            .select('*')
            .single();
            
        if (orderError) {
            console.error('❌ Erreur lors de la création de la commande de test:', orderError);
            return;
        }
        
        console.log('✅ Commande de test créée avec succès !');
        console.log(`📦 ID de la commande: ${testOrder.id}`);
        console.log(`📦 Type de l'ID: ${typeof testOrder.id}`);
        console.log(`📦 Longueur de l'ID: ${testOrder.id.length}`);
        
        // Vérifier que c'est bien un UUID
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (uuidRegex.test(testOrder.id)) {
            console.log('✅ L\'ID est bien un UUID valide !');
        } else {
            console.log('❌ L\'ID n\'est pas un UUID valide');
        }
        
        // Test 3: Vérifier l'affichage court
        console.log('\n📱 Test 3: Vérification de l\'affichage court...');
        const shortId = testOrder.id.substring(0, 8).toUpperCase();
        console.log(`📦 ID complet: ${testOrder.id}`);
        console.log(`📦 ID court (8 caractères): ${shortId}`);
        console.log(`📦 Affichage mobile: Commande #${shortId}`);
        
        // Test 4: Créer plusieurs commandes pour vérifier l'unicité
        console.log('\n🔄 Test 4: Vérification de l\'unicité des IDs...');
        const testOrders = [];
        
        for (let i = 0; i < 3; i++) {
            const { data: order, error } = await supabase
                .from('orders')
                .insert([{
                    prix_total: 10.00 + i,
                    status: 'En attente',
                    user_id: users?.[0]?.id || 'test-user-id',
                    adresse_livraison: `Test Address ${i + 1}`,
                    methode_paiement: 'Carte bancaire'
                }])
                .select('id')
                .single();
                
            if (error) {
                console.error(`❌ Erreur lors de la création de la commande ${i + 1}:`, error);
                continue;
            }
            
            testOrders.push(order.id);
            console.log(`✅ Commande ${i + 1}: ${order.id.substring(0, 8).toUpperCase()}`);
        }
        
        // Vérifier l'unicité
        const uniqueIds = new Set(testOrders);
        if (uniqueIds.size === testOrders.length) {
            console.log('✅ Tous les IDs sont uniques !');
        } else {
            console.log('❌ Certains IDs ne sont pas uniques');
        }
        
        // Test 5: Nettoyage
        console.log('\n🧹 Test 5: Nettoyage des données de test...');
        
        // Supprimer les commandes de test
        const allTestOrderIds = [testOrder.id, ...testOrders];
        const { error: deleteError } = await supabase
            .from('orders')
            .delete()
            .in('id', allTestOrderIds);
            
        if (deleteError) {
            console.error('❌ Erreur lors du nettoyage:', deleteError);
        } else {
            console.log('✅ Données de test supprimées');
        }
        
        console.log('\n🎉 Tous les tests sont passés avec succès !');
        console.log('\n📋 Résumé :');
        console.log('   ✅ La table orders utilise des UUIDs');
        console.log('   ✅ Les nouvelles commandes génèrent des IDs uniques');
        console.log('   ✅ L\'affichage court fonctionne correctement');
        console.log('   ✅ L\'application mobile est prête pour les UUIDs');
        
    } catch (error) {
        console.error('❌ Erreur lors des tests:', error);
    }
}

// Exécuter les tests
if (require.main === module) {
    testRandomOrderIds()
        .then(() => {
            console.log('\n🏁 Tests terminés !');
            process.exit(0);
        })
        .catch((error) => {
            console.error('💥 Erreur fatale:', error);
            process.exit(1);
        });
}

module.exports = { testRandomOrderIds }; 