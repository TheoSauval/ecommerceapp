const { supabase } = require('./config/supabase');
require('dotenv').config();

async function checkStockFunction() {
    console.log('🔍 Vérification de la fonction decrease_stock');
    console.log('============================================');
    
    try {
        // 1. Vérifier si la fonction existe
        console.log('1. Vérification de l\'existence de la fonction...');
        const { error: functionError } = await supabase.rpc('decrease_stock', { order_id_param: 999999 });
        
        if (functionError) {
            if (functionError.message.includes('function') || functionError.message.includes('does not exist')) {
                console.log('❌ La fonction decrease_stock n\'existe pas dans la base de données');
                console.log('   Erreur:', functionError.message);
                return false;
            } else {
                console.log('✅ La fonction existe (erreur attendue car la commande 999999 n\'existe pas)');
                console.log('   Erreur attendue:', functionError.message);
            }
        } else {
            console.log('✅ La fonction existe et s\'exécute sans erreur');
        }
        
        // 2. Vérifier la structure de la table order_variants
        console.log('\n2. Vérification de la structure de order_variants...');
        const { data: orderVariants, error: ovError } = await supabase
            .from('order_variants')
            .select('*')
            .limit(1);
            
        if (ovError) {
            console.log('❌ Erreur lors de l\'accès à order_variants:', ovError.message);
            return false;
        }
        
        console.log('✅ Table order_variants accessible');
        if (orderVariants.length > 0) {
            console.log('   Structure:', Object.keys(orderVariants[0]));
        }
        
        // 3. Vérifier la structure de la table product_variants
        console.log('\n3. Vérification de la structure de product_variants...');
        const { data: productVariants, error: pvError } = await supabase
            .from('product_variants')
            .select('*')
            .limit(1);
            
        if (pvError) {
            console.log('❌ Erreur lors de l\'accès à product_variants:', pvError.message);
            return false;
        }
        
        console.log('✅ Table product_variants accessible');
        if (productVariants.length > 0) {
            console.log('   Structure:', Object.keys(productVariants[0]));
        }
        
        // 4. Créer un test avec une vraie commande
        console.log('\n4. Test avec une vraie commande...');
        const { data: orders, error: ordersError } = await supabase
            .from('orders')
            .select('id, status')
            .eq('status', 'Payé')
            .limit(1);
            
        if (ordersError) {
            console.log('❌ Erreur lors de la récupération des commandes:', ordersError.message);
            return false;
        }
        
        if (orders.length === 0) {
            console.log('⚠️ Aucune commande payée trouvée pour le test');
            return true;
        }
        
        const testOrder = orders[0];
        console.log(`   Test avec la commande ${testOrder.id} (statut: ${testOrder.status})`);
        
        // Récupérer les variantes de cette commande
        const { data: orderVariantsForTest, error: ovTestError } = await supabase
            .from('order_variants')
            .select(`
                variant_id,
                quantity,
                product_variants (
                    id,
                    stock
                )
            `)
            .eq('order_id', testOrder.id);
            
        if (ovTestError) {
            console.log('❌ Erreur lors de la récupération des variantes de commande:', ovTestError.message);
            return false;
        }
        
        if (orderVariantsForTest.length === 0) {
            console.log('⚠️ Aucune variante trouvée pour cette commande');
            return true;
        }
        
        console.log(`   Variantes dans la commande: ${orderVariantsForTest.length}`);
        orderVariantsForTest.forEach((ov, index) => {
            console.log(`     ${index + 1}. Variante ${ov.variant_id}: ${ov.quantity}x (stock actuel: ${ov.product_variants.stock})`);
        });
        
        // 5. Tester la fonction decrease_stock
        console.log('\n5. Test de la fonction decrease_stock...');
        const { error: testError } = await supabase.rpc('decrease_stock', { order_id_param: testOrder.id });
        
        if (testError) {
            console.log('❌ Erreur lors de l\'exécution de decrease_stock:', testError.message);
            return false;
        }
        
        console.log('✅ Fonction decrease_stock exécutée sans erreur');
        
        // 6. Vérifier si le stock a été mis à jour
        console.log('\n6. Vérification de la mise à jour du stock...');
        for (const ov of orderVariantsForTest) {
            const { data: updatedVariant, error: updateError } = await supabase
                .from('product_variants')
                .select('stock')
                .eq('id', ov.variant_id)
                .single();
                
            if (updateError) {
                console.log(`❌ Erreur lors de la vérification de la variante ${ov.variant_id}:`, updateError.message);
            } else {
                const expectedStock = ov.product_variants.stock - ov.quantity;
                console.log(`   Variante ${ov.variant_id}: ${ov.product_variants.stock} -> ${updatedVariant.stock} (attendu: ${expectedStock})`);
                
                if (updatedVariant.stock === expectedStock) {
                    console.log('   ✅ Stock correctement mis à jour');
                } else {
                    console.log('   ❌ Stock non mis à jour correctement');
                }
            }
        }
        
        return true;
        
    } catch (error) {
        console.error('❌ Erreur générale:', error.message);
        return false;
    }
}

// Exécuter le test
checkStockFunction()
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