const { supabase } = require('./config/supabase');
require('dotenv').config();

async function checkOrdersStructure() {
    console.log('🔍 Vérification de la structure de la table orders');
    console.log('================================================');
    
    try {
        // 1. Vérifier la structure de la table orders
        console.log('1. Récupération d\'une commande pour voir sa structure...');
        const { data: orders, error: ordersError } = await supabase
            .from('orders')
            .select('*')
            .limit(1);
            
        if (ordersError) {
            console.log('❌ Erreur lors de la récupération des commandes:', ordersError.message);
            return false;
        }
        
        if (orders.length === 0) {
            console.log('⚠️ Aucune commande trouvée');
            return false;
        }
        
        const order = orders[0];
        console.log('✅ Commande trouvée:');
        console.log('   ID:', order.id, 'Type:', typeof order.id);
        console.log('   Statut:', order.status);
        console.log('   Tous les champs:', Object.keys(order));
        
        // 2. Vérifier la structure de order_variants
        console.log('\n2. Vérification de la structure de order_variants...');
        const { data: orderVariants, error: ovError } = await supabase
            .from('order_variants')
            .select('*')
            .limit(1);
            
        if (ovError) {
            console.log('❌ Erreur lors de la récupération des order_variants:', ovError.message);
            return false;
        }
        
        if (orderVariants.length > 0) {
            const ov = orderVariants[0];
            console.log('✅ Order variant trouvé:');
            console.log('   order_id:', ov.order_id, 'Type:', typeof ov.order_id);
            console.log('   variant_id:', ov.variant_id, 'Type:', typeof ov.variant_id);
            console.log('   Tous les champs:', Object.keys(ov));
        } else {
            console.log('⚠️ Aucun order_variant trouvé');
        }
        
        // 3. Vérifier la structure de product_variants
        console.log('\n3. Vérification de la structure de product_variants...');
        const { data: productVariants, error: pvError } = await supabase
            .from('product_variants')
            .select('*')
            .limit(1);
            
        if (pvError) {
            console.log('❌ Erreur lors de la récupération des product_variants:', pvError.message);
            return false;
        }
        
        if (productVariants.length > 0) {
            const pv = productVariants[0];
            console.log('✅ Product variant trouvé:');
            console.log('   id:', pv.id, 'Type:', typeof pv.id);
            console.log('   stock:', pv.stock, 'Type:', typeof pv.stock);
            console.log('   Tous les champs:', Object.keys(pv));
        } else {
            console.log('⚠️ Aucun product_variant trouvé');
        }
        
        // 4. Tester une requête directe pour voir l'erreur exacte
        console.log('\n4. Test de requête directe...');
        if (orderVariants.length > 0) {
            const ov = orderVariants[0];
            console.log(`   Test avec order_id: ${ov.order_id} (type: ${typeof ov.order_id})`);
            
            // Essayer de récupérer les variantes de cette commande
            const { data: testVariants, error: testError } = await supabase
                .from('order_variants')
                .select('*')
                .eq('order_id', ov.order_id);
                
            if (testError) {
                console.log('❌ Erreur lors du test:', testError.message);
            } else {
                console.log(`✅ Test réussi, ${testVariants.length} variantes trouvées`);
            }
        }
        
        return true;
        
    } catch (error) {
        console.error('❌ Erreur générale:', error.message);
        return false;
    }
}

// Exécuter le test
checkOrdersStructure()
    .then(success => {
        if (success) {
            console.log('\n✅ Vérification terminée avec succès');
        } else {
            console.log('\n❌ Vérification échouée');
        }
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Erreur fatale:', error);
        process.exit(1);
    }); 