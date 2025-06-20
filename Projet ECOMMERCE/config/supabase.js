const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuration Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('Variables d\'environnement Supabase manquantes');
    console.error('Veuillez configurer SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY dans votre fichier .env');
    process.exit(1);
}

// Client Supabase avec la clé de service (accès complet)
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

// Client Supabase public (pour les opérations côté client)
const supabasePublic = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
);

// Test de la connexion
const testConnection = async () => {
    if (!supabase) {
        console.log('⚠️  Supabase non configuré - Variables d\'environnement manquantes');
        console.log('   Configurez SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et SUPABASE_ANON_KEY dans votre fichier .env');
        return;
    }
    
    try {
        // Test simple de connexion sans tester une table spécifique
        const { data, error } = await supabase.auth.getSession();
        if (error) {
            console.log('⚠️  Erreur de connexion à Supabase:', error.message);
        } else {
            console.log('✅ Connexion à Supabase établie avec succès');
        }
    } catch (err) {
        console.log('⚠️  Erreur de connexion à Supabase:', err.message);
    }
};

// Exécuter le test de connexion au démarrage
testConnection();

module.exports = { 
    supabase, 
    supabasePublic,
    testConnection 
}; 