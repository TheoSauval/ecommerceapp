require('dotenv').config();
const { supabase } = require('./config/supabase');

/**
 * Script pour tester la récupération des données de commandes
 */
async function testOrdersData() {
    console.log('🧪 Test de récupération des données de commandes');
    console.log('===============================================');
    
    try {
        // Récupérer une commande récente avec toutes les données
        const { data: orders, error: ordersError } = await supabase
            .from('orders')
            .select(`
                *,
                order_variants (
                    order_id,
                    variant_id,
                    quantity,
                    unit_price,
                    product_variants (
                        *,
                        products (*),
                        colors (*),
                        heights (*)
                    )
                )
            `)
            .order('created_at', { ascending: false })
            .limit(1);
        
        if (ordersError) {
            console.error('❌ Erreur lors de la récupération des commandes:', ordersError);
            return;
        }
        
        if (!orders || orders.length === 0) {
            console.log('❌ Aucune commande trouvée');
            return;
        }
        
        const order = orders[0];
        console.log(`📋 Commande trouvée: ID ${order.id}`);
        console.log(`   Statut: ${order.status}`);
        console.log(`   Prix total: ${order.prix_total} EUR`);
        console.log(`   Créée: ${new Date(order.created_at).toLocaleString()}`);
        console.log('');
        
        if (order.order_variants && order.order_variants.length > 0) {
            console.log('📦 Articles de la commande:');
            console.log('===========================');
            
            order.order_variants.forEach((variant, index) => {
                console.log(`${index + 1}. Variante ID: ${variant.variant_id}`);
                console.log(`   Quantité: ${variant.quantity}`);
                console.log(`   Prix unitaire: ${variant.unit_price} EUR`);
                
                if (variant.product_variants) {
                    const product = variant.product_variants.products;
                    const color = variant.product_variants.colors;
                    const height = variant.product_variants.heights;
                    
                    console.log(`   Produit: ${product?.nom || 'Nom manquant'}`);
                    console.log(`   Description: ${product?.description || 'Description manquante'}`);
                    console.log(`   Prix de base: ${product?.prix_base || 'Prix manquant'} EUR`);
                    console.log(`   Couleur: ${color?.nom || 'Couleur manquante'}`);
                    console.log(`   Taille: ${height?.nom || 'Taille manquante'}`);
                    
                    if (product?.images && product.images.length > 0) {
                        console.log(`   Images: ${product.images.length} image(s) trouvée(s)`);
                        product.images.forEach((image, imgIndex) => {
                            console.log(`     ${imgIndex + 1}. ${image}`);
                        });
                    } else {
                        console.log(`   Images: ❌ Aucune image trouvée`);
                    }
                } else {
                    console.log(`   Produit: ❌ Données de produit manquantes`);
                }
                console.log('');
            });
        } else {
            console.log('❌ Aucun article trouvé dans cette commande');
        }
        
        // Test de la transformation des données
        console.log('🔄 Test de la transformation des données:');
        console.log('=========================================');
        
        const transformedOrder = {
            ...order,
            order_variants: order.order_variants?.map(variant => ({
                ...variant,
                product_variant: variant.product_variants,
                product_variants: undefined
            }))
        };
        
        console.log('✅ Données transformées pour l\'app Swift:');
        console.log(JSON.stringify(transformedOrder, null, 2));
        
    } catch (error) {
        console.error('❌ Erreur lors du test:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

// Exécuter le test
testOrdersData(); 