const { supabase, supabasePublic } = require('./config/supabase');

async function diagnoseSessionIssue() {
    console.log('🔍 Diagnostic du problème de sessions multiples Supabase...\n');

    try {
        // 1. Vérifier la configuration actuelle
        console.log('📋 Configuration Supabase actuelle:');
        console.log('   - SUPABASE_URL:', process.env.SUPABASE_URL ? '✅ Configuré' : '❌ Manquant');
        console.log('   - SUPABASE_ANON_KEY:', process.env.SUPABASE_ANON_KEY ? '✅ Configuré' : '❌ Manquant');
        console.log('   - SUPABASE_SERVICE_ROLE_KEY:', process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ Configuré' : '❌ Manquant');

        // 2. Test de connexion multiple
        console.log('\n🧪 Test de sessions multiples...');
        
        // Créer deux clients Supabase séparés pour simuler l'app mobile et le dashboard
        const { createClient } = require('@supabase/supabase-js');
        
        // Client 1 (simulation app mobile)
        const client1 = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_ANON_KEY,
            {
                auth: {
                    autoRefreshToken: true,
                    persistSession: false,
                    detectSessionInUrl: false,
                    multiTab: true,
                    storage: {
                        getItem: (key) => {
                            // Stockage séparé pour client1
                            return global.client1Storage?.[key] || null;
                        },
                        setItem: (key, value) => {
                            if (!global.client1Storage) global.client1Storage = {};
                            global.client1Storage[key] = value;
                        },
                        removeItem: (key) => {
                            if (global.client1Storage) delete global.client1Storage[key];
                        }
                    }
                }
            }
        );

        // Client 2 (simulation dashboard)
        const client2 = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_ANON_KEY,
            {
                auth: {
                    autoRefreshToken: true,
                    persistSession: false,
                    detectSessionInUrl: false,
                    multiTab: true,
                    storage: {
                        getItem: (key) => {
                            // Stockage séparé pour client2
                            return global.client2Storage?.[key] || null;
                        },
                        setItem: (key, value) => {
                            if (!global.client2Storage) global.client2Storage = {};
                            global.client2Storage[key] = value;
                        },
                        removeItem: (key) => {
                            if (global.client2Storage) delete global.client2Storage[key];
                        }
                    }
                }
            }
        );

        // 3. Test de connexion séquentielle
        console.log('\n📱 Test 1: Connexion client 1 (app mobile)...');
        
        // Créer un utilisateur de test
        const testEmail1 = `test-mobile-${Date.now()}@example.com`;
        const { data: user1, error: createError1 } = await supabase.auth.admin.createUser({
            email: testEmail1,
            password: 'password123',
            email_confirm: true,
            user_metadata: {
                nom: 'Test',
                prenom: 'Mobile',
                age: 25,
                role: 'user'
            }
        });

        if (createError1) {
            console.error('❌ Erreur création utilisateur 1:', createError1);
            return;
        }

        // Connexion client 1
        const { data: session1, error: loginError1 } = await client1.auth.signInWithPassword({
            email: testEmail1,
            password: 'password123'
        });

        if (loginError1) {
            console.error('❌ Erreur connexion client 1:', loginError1);
            return;
        }

        console.log('✅ Client 1 connecté, token:', session1.session.access_token.substring(0, 20) + '...');

        // 4. Test de connexion client 2
        console.log('\n💻 Test 2: Connexion client 2 (dashboard)...');
        
        const testEmail2 = `test-dashboard-${Date.now()}@example.com`;
        const { data: user2, error: createError2 } = await supabase.auth.admin.createUser({
            email: testEmail2,
            password: 'password123',
            email_confirm: true,
            user_metadata: {
                nom: 'Test',
                prenom: 'Dashboard',
                age: 30,
                role: 'vendor'
            }
        });

        if (createError2) {
            console.error('❌ Erreur création utilisateur 2:', createError2);
            return;
        }

        // Connexion client 2
        const { data: session2, error: loginError2 } = await client2.auth.signInWithPassword({
            email: testEmail2,
            password: 'password123'
        });

        if (loginError2) {
            console.error('❌ Erreur connexion client 2:', loginError2);
            return;
        }

        console.log('✅ Client 2 connecté, token:', session2.session.access_token.substring(0, 20) + '...');

        // 5. Vérifier que les sessions sont indépendantes
        console.log('\n🔍 Test 3: Vérification de l\'indépendance des sessions...');

        // Vérifier que client 1 est toujours connecté
        const { data: { user: user1Check }, error: checkError1 } = await client1.auth.getUser();
        if (checkError1) {
            console.log('❌ Client 1 déconnecté après connexion client 2');
        } else {
            console.log('✅ Client 1 toujours connecté:', user1Check.email);
        }

        // Vérifier que client 2 est connecté
        const { data: { user: user2Check }, error: checkError2 } = await client2.auth.getUser();
        if (checkError2) {
            console.log('❌ Client 2 déconnecté');
        } else {
            console.log('✅ Client 2 connecté:', user2Check.email);
        }

        // 6. Test d'utilisation des tokens
        console.log('\n🔐 Test 4: Test d\'utilisation des tokens...');

        // Test avec token client 1
        const { data: profile1, error: profileError1 } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user1.user.id)
            .single();

        if (profileError1) {
            console.log('❌ Erreur récupération profil client 1:', profileError1);
        } else {
            console.log('✅ Profil client 1 récupéré:', profile1.nom, profile1.prenom);
        }

        // Test avec token client 2
        const { data: profile2, error: profileError2 } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user2.user.id)
            .single();

        if (profileError2) {
            console.log('❌ Erreur récupération profil client 2:', profileError2);
        } else {
            console.log('✅ Profil client 2 récupéré:', profile2.nom, profile2.prenom);
        }

        // 7. Nettoyage
        console.log('\n🧹 Nettoyage des utilisateurs de test...');
        await supabase.auth.admin.deleteUser(user1.user.id);
        await supabase.auth.admin.deleteUser(user2.user.id);
        console.log('✅ Utilisateurs de test supprimés');

        // 8. Résumé
        console.log('\n📊 Résumé du diagnostic:');
        if (user1Check && user2Check) {
            console.log('✅ Les sessions multiples fonctionnent correctement');
            console.log('✅ Le problème n\'est pas lié aux sessions Supabase');
            console.log('💡 Le problème pourrait être lié à la configuration côté client');
        } else {
            console.log('❌ Problème de sessions multiples détecté');
            console.log('🔧 Solution: Utiliser des clients Supabase séparés');
        }

    } catch (error) {
        console.error('❌ Erreur lors du diagnostic:', error);
    }
}

// Fonction pour créer une configuration Supabase optimisée
function createOptimizedSupabaseConfig() {
    console.log('\n🔧 Configuration Supabase optimisée pour sessions multiples:');
    
    const config = `
// Configuration optimisée pour sessions multiples
const { createClient } = require('@supabase/supabase-js');

// Client pour l'app mobile
const createMobileClient = () => {
    return createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY,
        {
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
        }
    );
};

// Client pour le dashboard
const createDashboardClient = () => {
    return createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY,
        {
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
        }
    );
};

module.exports = {
    createMobileClient,
    createDashboardClient
};
`;

    console.log(config);
}

// Exécuter le diagnostic
async function main() {
    await diagnoseSessionIssue();
    createOptimizedSupabaseConfig();
}

// Exécuter si le script est appelé directement
if (require.main === module) {
    main();
}

module.exports = {
    diagnoseSessionIssue,
    createOptimizedSupabaseConfig
}; 