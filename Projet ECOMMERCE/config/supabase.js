const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuration Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseServiceKey || !supabaseAnonKey) {
    console.error('Variables d\'environnement Supabase manquantes');
    console.error('Veuillez configurer SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et SUPABASE_ANON_KEY dans votre fichier .env');
    process.exit(1);
}

// Client Supabase avec la clé de service (accès complet) - pour les opérations admin
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false,
        detectSessionInUrl: false
    }
});

// Client Supabase public pour l'app mobile (stockage séparé)
const createMobileClient = () => {
    return createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
            autoRefreshToken: true,
            persistSession: false,
            detectSessionInUrl: false,
            multiTab: true,
            storage: {
                getItem: (key) => {
                    // Stockage séparé pour l'app mobile
                    return global.mobileStorage?.[key] || null;
                },
                setItem: (key, value) => {
                    if (!global.mobileStorage) global.mobileStorage = {};
                    global.mobileStorage[key] = value;
                },
                removeItem: (key) => {
                    if (global.mobileStorage) delete global.mobileStorage[key];
                }
            }
        }
    });
};

// Client Supabase public pour le dashboard (stockage séparé)
const createDashboardClient = () => {
    return createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
            autoRefreshToken: true,
            persistSession: false,
            detectSessionInUrl: false,
            multiTab: true,
            storage: {
                getItem: (key) => {
                    // Stockage séparé pour le dashboard
                    return global.dashboardStorage?.[key] || null;
                },
                setItem: (key, value) => {
                    if (!global.dashboardStorage) global.dashboardStorage = {};
                    global.dashboardStorage[key] = value;
                },
                removeItem: (key) => {
                    if (global.dashboardStorage) delete global.dashboardStorage[key];
                }
            }
        }
    });
};

// Client Supabase public générique (pour compatibilité)
const supabasePublic = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
        autoRefreshToken: true,
        persistSession: false,
        detectSessionInUrl: false,
        multiTab: true
    }
});

// Test de la connexion
const testConnection = async () => {
    try {
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
    createMobileClient,
    createDashboardClient,
    testConnection 
}; 