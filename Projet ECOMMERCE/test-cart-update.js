require('dotenv').config();
const cartService = require('./services/cartService');

async function testCartUpdate() {
    try {
        console.log('🧪 Test de mise à jour de quantité dans le panier');
        console.log('===============================================');
        
        const userId = '4aa25ca2-8053-4e91-8786-b9ccf8b12854';
        const cartItemId = 21; // ID de l'article dans ton panier
        
        console.log(`📋 Mise à jour de l'article ${cartItemId} pour l'utilisateur: ${userId}`);
        
        // Test 1: Augmenter la quantité à 3
        console.log('\n🔄 Test 1: Augmenter la quantité à 3');
        const result1 = await cartService.updateCartItem(cartItemId, userId, 3);
        console.log('✅ Résultat:', result1);
        
        // Attendre un peu
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Test 2: Diminuer la quantité à 1
        console.log('\n🔄 Test 2: Diminuer la quantité à 1');
        const result2 = await cartService.updateCartItem(cartItemId, userId, 1);
        console.log('✅ Résultat:', result2);
        
        // Attendre un peu
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Test 3: Vérifier l'état final
        console.log('\n📋 Vérification de l\'état final du panier');
        const finalCart = await cartService.getCart(userId);
        console.log('✅ Panier final:', JSON.stringify(finalCart, null, 2));
        
    } catch (error) {
        console.error('❌ Erreur:', error.message);
        console.error(error);
    }
}

testCartUpdate(); 