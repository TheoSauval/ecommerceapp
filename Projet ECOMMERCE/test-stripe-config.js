/**
 * CONFIGURATION POUR LES TESTS STRIPE
 * ===================================
 * 
 * Ce fichier contient la configuration nécessaire pour exécuter
 * les tests de paiement Stripe avec votre base de données Supabase.
 */

require('dotenv').config();

// =====================================================
// VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
// =====================================================

const requiredEnvVars = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'STRIPE_SECRET_KEY'
];

const optionalEnvVars = [
    'STRIPE_WEBHOOK_SECRET',
    'FRONTEND_URL'
];

function checkEnvironmentVariables() {
    console.log('🔧 Vérification des variables d\'environnement...');
    
    const missingVars = [];
    
    requiredEnvVars.forEach(varName => {
        if (!process.env[varName]) {
            missingVars.push(varName);
        }
    });
    
    if (missingVars.length > 0) {
        console.error('❌ Variables d\'environnement manquantes:');
        missingVars.forEach(varName => {
            console.error(`   - ${varName}`);
        });
        console.error('\n📝 Assurez-vous d\'avoir un fichier .env avec ces variables.');
        return false;
    }
    
    console.log('✅ Variables d\'environnement requises configurées');
    
    // Vérifier les variables optionnelles
    const missingOptional = [];
    optionalEnvVars.forEach(varName => {
        if (!process.env[varName]) {
            missingOptional.push(varName);
        }
    });
    
    if (missingOptional.length > 0) {
        console.log('⚠️  Variables d\'environnement optionnelles manquantes:');
        missingOptional.forEach(varName => {
            console.log(`   - ${varName} (utilisera les valeurs par défaut)`);
        });
    }
    
    return true;
}

// =====================================================
// CONFIGURATION DES TESTS
// =====================================================

const testConfig = {
    // Configuration des tests
    testUser: {
        email: `sauvaltheo@gmail.com`,
        password: 'azerty',
        nom: 'Sauval',
        prenom: 'Theo',
        age: 22,
        role: 'user'
    },
    
    // Configuration des commandes de test
    testOrder: {
        quantity: 2,
        adresse_livraison: '123 Rue Test, 75001 Paris',
        methode_paiement: 'Stripe'
    },
    
    // Configuration Stripe
    stripe: {
        currency: 'eur',
        payment_method_types: ['card'],
        mode: 'payment',
        success_url: process.env.FRONTEND_URL ? 
            `${process.env.FRONTEND_URL}/payment/success?session_id={CHECKOUT_SESSION_ID}` :
            'http://localhost:3000/payment/success?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: process.env.FRONTEND_URL ? 
            `${process.env.FRONTEND_URL}/payment/cancel` :
            'http://localhost:3000/payment/cancel'
    },
    
    // Configuration des cartes de test Stripe
    testCards: {
        success: '4242424242424242', // Paiement réussi
        decline: '4000000000000002', // Paiement refusé
        insufficient_funds: '4000000000009995', // Fonds insuffisants
        expired: '4000000000000069', // Carte expirée
        incorrect_cvc: '4000000000000127' // CVC incorrect
    }
};

// =====================================================
// FONCTIONS UTILITAIRES
// =====================================================

/**
 * Générer un email unique pour les tests
 */
function generateTestEmail() {
    return `test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}@example.com`;
}

/**
 * Vérifier la connectivité à Supabase
 */
async function checkSupabaseConnection() {
    const { supabase } = require('./config/supabase');
    
    try {
        const { data, error } = await supabase
            .from('products')
            .select('count')
            .limit(1);
            
        if (error) {
            console.error('❌ Erreur de connexion à Supabase:', error);
            return false;
        }
        
        console.log('✅ Connexion à Supabase établie');
        return true;
    } catch (error) {
        console.error('❌ Erreur de connexion à Supabase:', error);
        return false;
    }
}

/**
 * Vérifier la connectivité à Stripe
 */
async function checkStripeConnection() {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    
    try {
        const account = await stripe.accounts.retrieve();
        console.log('✅ Connexion à Stripe établie');
        console.log(`   Compte: ${account.business_profile?.name || 'Compte Stripe'}`);
        console.log(`   Mode: ${account.charges_enabled ? 'Production' : 'Test'}`);
        return true;
    } catch (error) {
        console.error('❌ Erreur de connexion à Stripe:', error);
        return false;
    }
}

/**
 * Vérifier que des données de test existent
 */
async function checkTestData() {
    const { supabase } = require('./config/supabase');
    
    console.log('\n📊 Vérification des données de test...');
    
    // Vérifier les produits
    const { data: products, error: productsError } = await supabase
        .from('products')
        .select('count')
        .eq('actif', true);
        
    if (productsError) {
        console.error('❌ Erreur lors de la vérification des produits:', productsError);
        return false;
    }
    
    console.log(`   Produits actifs: ${products.length}`);
    
    // Vérifier les variantes
    const { data: variants, error: variantsError } = await supabase
        .from('product_variants')
        .select('count')
        .eq('actif', true)
        .gt('stock', 0);
        
    if (variantsError) {
        console.error('❌ Erreur lors de la vérification des variantes:', variantsError);
        return false;
    }
    
    console.log(`   Variantes en stock: ${variants.length}`);
    
    // Vérifier les vendeurs
    const { data: vendors, error: vendorsError } = await supabase
        .from('vendors')
        .select('count');
        
    if (vendorsError) {
        console.error('❌ Erreur lors de la vérification des vendeurs:', vendorsError);
        return false;
    }
    
    console.log(`   Vendeurs: ${vendors.length}`);
    
    return true;
}

// =====================================================
// EXÉCUTION DES VÉRIFICATIONS
// =====================================================

async function runPreflightChecks() {
    console.log('🚀 VÉRIFICATIONS PRÉALABLES AUX TESTS');
    console.log('=====================================');
    
    // Vérifier les variables d'environnement
    if (!checkEnvironmentVariables()) {
        return false;
    }
    
    // Vérifier la connexion à Supabase
    if (!(await checkSupabaseConnection())) {
        return false;
    }
    
    // Vérifier la connexion à Stripe
    if (!(await checkStripeConnection())) {
        return false;
    }
    
    // Vérifier les données de test
    if (!(await checkTestData())) {
        return false;
    }
    
    console.log('\n✅ Toutes les vérifications sont passées !');
    console.log('🎯 Vous pouvez maintenant exécuter les tests.');
    
    return true;
}

// =====================================================
// EXPORTS
// =====================================================

module.exports = {
    testConfig,
    generateTestEmail,
    checkEnvironmentVariables,
    checkSupabaseConnection,
    checkStripeConnection,
    checkTestData,
    runPreflightChecks
};

// Exécuter les vérifications si le fichier est appelé directement
if (require.main === module) {
    runPreflightChecks();
} 