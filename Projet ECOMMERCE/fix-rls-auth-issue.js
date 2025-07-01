const { supabase, supabasePublic } = require('./config/supabase');

async function diagnoseRLSAuthIssue() {
    console.log('🔍 Diagnostic du problème d\'authentification RLS\n');

    // Test 1: Vérifier les utilisateurs existants
    console.log('1️⃣ Vérification des utilisateurs existants...');
    const { data: { users }, error: usersError } = await supabase.auth.admin.listUsers();
    
    if (usersError) {
        console.error('❌ Erreur lors de la récupération des utilisateurs:', usersError);
        return;
    }

    console.log(`✅ ${users.length} utilisateurs trouvés dans auth.users`);
    
    // Prendre le premier utilisateur pour les tests
    const testUser = users[0];
    console.log('👤 Utilisateur de test:', {
        id: testUser.id,
        email: testUser.email,
        metadata: testUser.user_metadata
    });

    // Test 2: Vérifier les profils existants
    console.log('\n2️⃣ Vérification des profils existants...');
    const { data: profiles, error: profilesError } = await supabase
        .from('user_profiles')
        .select('*');

    if (profilesError) {
        console.error('❌ Erreur lors de la récupération des profils:', profilesError);
    } else {
        console.log(`✅ ${profiles.length} profils trouvés dans user_profiles`);
        if (profiles.length > 0) {
            console.log('📋 Premier profil:', profiles[0]);
        }
    }

    // Test 3: Tester l'accès avec le client public (comme le middleware)
    console.log('\n3️⃣ Test d\'accès avec client public (comme le middleware)...');
    const { data: publicProfile, error: publicError } = await supabasePublic
        .from('user_profiles')
        .select('*')
        .eq('id', testUser.id)
        .single();

    if (publicError) {
        console.log('❌ Erreur avec client public (attendu):', publicError.message);
    } else {
        console.log('✅ Accès réussi avec client public:', publicProfile);
    }

    // Test 4: Tester l'accès avec le client admin
    console.log('\n4️⃣ Test d\'accès avec client admin...');
    const { data: adminProfile, error: adminError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', testUser.id)
        .single();

    if (adminError) {
        console.error('❌ Erreur avec client admin:', adminError);
    } else {
        console.log('✅ Accès réussi avec client admin:', adminProfile);
    }

    // Test 5: Vérifier les politiques RLS
    console.log('\n5️⃣ Vérification des politiques RLS...');
    const { data: rlsPolicies, error: rlsError } = await supabase
        .rpc('get_rls_policies', { table_name: 'user_profiles' })
        .catch(() => ({ data: null, error: 'Fonction non disponible' }));

    if (rlsError) {
        console.log('ℹ️ Impossible de récupérer les politiques RLS via RPC');
    } else {
        console.log('📋 Politiques RLS:', rlsPolicies);
    }

    return { testUser, profiles };
}

async function fixRLSAuthIssue() {
    console.log('\n🔧 Correction du problème d\'authentification RLS\n');

    // Solution 1: Modifier le middleware pour utiliser le client admin
    console.log('1️⃣ Modification du middleware d\'authentification...');
    
    // Créer une version corrigée du middleware
    const correctedMiddleware = `
// middleware/auth.js - VERSION CORRIGÉE
const { supabase } = require('../config/supabase');

const authenticateToken = async (req, res, next) => {
    try {
        console.log('🔐 Middleware d\'authentification appelé');

        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({ message: 'Token d\'accès requis' });
        }

        // Vérifier le token avec Supabase
        const { data: { user }, error } = await supabase.auth.getUser(token);

        if (error || !user) {
            return res.status(401).json({ message: 'Token invalide' });
        }

        console.log('✅ Utilisateur authentifié:', user.id);

        // Récupérer le profil utilisateur avec le client admin (bypass RLS)
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        if (profileError) {
            console.log('❌ Erreur profil:', profileError);
            return res.status(401).json({ message: 'Profil utilisateur introuvable' });
        }

        console.log('✅ Profil récupéré:', profile);

        // Ajouter les informations utilisateur à la requête
        req.user = {
            ...profile,
            email: user.email
        };

        next();
    } catch (error) {
        console.error('❌ Erreur d\'authentification:', error);
        return res.status(401).json({ message: 'Erreur d\'authentification' });
    }
};

module.exports = { authenticateToken };
`;

    console.log('📝 Code du middleware corrigé généré');
    console.log('💡 Le problème était que le middleware utilisait supabasePublic au lieu de supabase');

    // Solution 2: Alternative - Désactiver temporairement RLS pour les tests
    console.log('\n2️⃣ Alternative - Désactiver temporairement RLS...');
    
    const disableRLS = `
-- Désactiver temporairement RLS pour les tests
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- OU créer une politique plus permissive pour les tests
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Allow all profile access for testing" ON public.user_profiles FOR ALL USING (true);
`;

    console.log('📝 Script SQL pour désactiver RLS généré');

    return { correctedMiddleware, disableRLS };
}

async function testFixedAuth() {
    console.log('\n🧪 Test de l\'authentification corrigée\n');

    // Simuler une requête avec token
    const testToken = 'test-token'; // À remplacer par un vrai token
    
    try {
        // Test avec le client admin
        const { data: { user }, error } = await supabase.auth.getUser(testToken);
        
        if (error) {
            console.log('❌ Test avec token invalide (attendu):', error.message);
        } else {
            console.log('✅ Test réussi avec token valide');
            
            // Tester la récupération du profil
            const { data: profile, error: profileError } = await supabase
                .from('user_profiles')
                .select('*')
                .eq('id', user.id)
                .single();

            if (profileError) {
                console.log('❌ Erreur profil:', profileError);
            } else {
                console.log('✅ Profil récupéré avec succès:', profile);
            }
        }
    } catch (error) {
        console.error('❌ Erreur lors du test:', error);
    }
}

// Exécution du diagnostic
async function main() {
    try {
        const { testUser, profiles } = await diagnoseRLSAuthIssue();
        const { correctedMiddleware, disableRLS } = await fixRLSAuthIssue();
        
        console.log('\n📋 RÉSUMÉ DU DIAGNOSTIC');
        console.log('========================');
        console.log('❌ Problème identifié: Le middleware utilise supabasePublic (client anonyme)');
        console.log('✅ Solution: Utiliser supabase (client admin) dans le middleware');
        console.log('🔧 Alternative: Désactiver temporairement RLS pour les tests');
        
        console.log('\n📝 ACTIONS RECOMMANDÉES:');
        console.log('1. Remplacer supabasePublic par supabase dans middleware/auth.js');
        console.log('2. Ou exécuter le script SQL pour désactiver RLS temporairement');
        console.log('3. Tester la connexion sur l\'app mobile et le dashboard');
        
    } catch (error) {
        console.error('❌ Erreur lors du diagnostic:', error);
    }
}

if (require.main === module) {
    main();
}

module.exports = {
    diagnoseRLSAuthIssue,
    fixRLSAuthIssue,
    testFixedAuth
}; 