/**
 * Script pour tester le parsing des URLs de retour Stripe
 */

// URL de test basée sur votre exemple
const testURL = "ecommerceshop://payment/success?session_id=cs_test_a1kC9JMe1n5azCBHtY4LlFRyC4hnXmJFvcQ77DZ4LDPZ0GoSPX5AtvTvhW";

console.log('🧪 Test de parsing d\'URL de retour Stripe');
console.log('==========================================');
console.log(`URL de test: ${testURL}`);
console.log('');

// Simuler le parsing comme dans URLSchemeHandler.swift
function parsePaymentResult(urlString) {
    const url = new URL(urlString);
    const path = url.pathname;
    const queryItems = Array.from(url.searchParams.entries()).map(([key, value]) => ({ name: key, value }));
    
    console.log('📋 Analyse de l\'URL:');
    console.log(`   Scheme: ${url.protocol.replace(':', '')}`);
    console.log(`   Path: ${path}`);
    console.log(`   Query items:`, queryItems);
    console.log('');
    
    // Logique de parsing (similaire à Swift)
    if (path.includes('success') || urlString.includes('success')) {
        const sessionId = queryItems.find(item => item.name === 'session_id')?.value;
        console.log(`✅ Paiement réussi détecté, session ID: ${sessionId || 'nil'}`);
        return { type: 'success', sessionId };
    } 
    else if (path.includes('cancel') || urlString.includes('cancel')) {
        console.log('❌ Paiement annulé détecté');
        return { type: 'cancelled' };
    } 
    else if (queryItems.find(item => item.name === 'session_id')) {
        const sessionId = queryItems.find(item => item.name === 'session_id')?.value;
        console.log(`✅ Paiement réussi détecté (via session_id), session ID: ${sessionId || 'nil'}`);
        return { type: 'success', sessionId };
    }
    else {
        const urlStringLower = urlString.toLowerCase();
        if (urlStringLower.includes('success')) {
            const sessionId = queryItems.find(item => item.name === 'session_id')?.value;
            console.log(`✅ Paiement réussi détecté (fallback), session ID: ${sessionId || 'nil'}`);
            return { type: 'success', sessionId };
        } else if (urlStringLower.includes('cancel')) {
            console.log('❌ Paiement annulé détecté (fallback)');
            return { type: 'cancelled' };
        } else {
            console.log(`❌ URL de retour inconnue: ${urlString}`);
            return { type: 'error', message: `URL de retour inconnue: ${urlString}` };
        }
    }
}

// Tester l'URL
const result = parsePaymentResult(testURL);
console.log('');
console.log('🎯 Résultat final:', result);

// Tester d'autres formats d'URL possibles
console.log('');
console.log('🧪 Tests avec d\'autres formats d\'URL:');
console.log('=====================================');

const testURLs = [
    "ecommerceshop://payment/success?session_id=cs_test_123",
    "ecommerceshop://success?session_id=cs_test_123",
    "ecommerceshop://payment/cancel",
    "ecommerceshop://cancel",
    "ecommerceshop://?session_id=cs_test_123",
    "ecommerceshop://unknown?session_id=cs_test_123"
];

testURLs.forEach((url, index) => {
    console.log(`\nTest ${index + 1}: ${url}`);
    const testResult = parsePaymentResult(url);
    console.log(`   Résultat: ${testResult.type}${testResult.sessionId ? ` (session: ${testResult.sessionId})` : ''}`);
}); 