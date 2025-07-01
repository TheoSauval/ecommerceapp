require('dotenv').config();
const cartService = require('./services/cartService');

async function testCartData() {
    try {
        console.log('🧪 Test de récupération des données du panier');
        console.log('==========================================');
        
        // Utiliser l'ID utilisateur de tes logs
        const userId = '4aa25ca2-8053-4e91-8786-b9ccf8b12854';
        
        console.log(`📋 Récupération du panier pour l'utilisateur: ${userId}`);
        
        const cartItems = await cartService.getCart(userId);
        
        console.log(`✅ ${cartItems.length} articles trouvés dans le panier`);
        console.log('');
        
        cartItems.forEach((item, index) => {
            console.log(`📦 Article ${index + 1}:`);
            console.log(`   ID: ${item.id}`);
            console.log(`   Variant ID: ${item.variant_id}`);
            console.log(`   Quantité: ${item.quantity}`);
            console.log(`   User ID: ${item.user_id}`);
            console.log('');
            
            console.log('🔍 Structure des données:');
            console.log('   product_variant:', item.product_variant ? '✅ Présent' : '❌ Absent');
            
            if (item.product_variant) {
                console.log('   product_variant.id:', item.product_variant.id);
                console.log('   product_variant.product_id:', item.product_variant.product_id);
                console.log('   product_variant.product:', item.product_variant.product ? '✅ Présent' : '❌ Absent');
                
                if (item.product_variant.product) {
                    console.log('   product_variant.product.nom:', item.product_variant.product.nom);
                    console.log('   product_variant.product.id:', item.product_variant.product.id);
                }
                
                console.log('   product_variant.color:', item.product_variant.color ? '✅ Présent' : '❌ Absent');
                console.log('   product_variant.height:', item.product_variant.height ? '✅ Présent' : '❌ Absent');
            }
            
            console.log('');
            console.log('📄 Données complètes (JSON):');
            console.log(JSON.stringify(item, null, 2));
            console.log('=' .repeat(50));
            console.log('');
        });
        
    } catch (error) {
        console.error('❌ Erreur:', error.message);
        console.error(error);
    }
}

testCartData(); 