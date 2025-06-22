#!/usr/bin/env node

/**
 * SCRIPT D'EXÉCUTION DES TESTS STRIPE
 * ===================================
 * 
 * Ce script exécute les tests de paiement Stripe de manière simple.
 * 
 * Utilisation:
 *   node run-stripe-tests.js
 *   npm run test:stripe
 */

const { runPreflightChecks } = require('./test-stripe-config');
const StripePaymentTester = require('./test-stripe-payment');

async function main() {
    console.log('🎯 LANCEMENT DES TESTS DE PAIEMENT STRIPE');
    console.log('==========================================\n');
    
    try {
        // Vérifications préalables
        const checksPassed = await runPreflightChecks();
        
        if (!checksPassed) {
            console.error('\n❌ Les vérifications préalables ont échoué.');
            console.error('🔧 Veuillez corriger les problèmes avant de relancer les tests.');
            process.exit(1);
        }
        
        console.log('\n' + '='.repeat(50));
        console.log('DÉBUT DES TESTS DE PAIEMENT');
        console.log('='.repeat(50));
        
        // Exécuter les tests
        const tester = new StripePaymentTester();
        await tester.runAllTests();
        
        console.log('\n' + '='.repeat(50));
        console.log('FIN DES TESTS');
        console.log('='.repeat(50));
        
    } catch (error) {
        console.error('\n💥 ERREUR FATALE:', error);
        process.exit(1);
    }
}

// Exécuter le script principal
if (require.main === module) {
    main();
}

module.exports = main; 