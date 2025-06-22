const { supabase } = require('./config/supabase');

async function testUserProfile() {
    const userId = '4aa25ca2-8053-4e91-8786-b9ccf8b12854'; // L'ID de votre utilisateur

    console.log('🔍 Test du profil utilisateur pour ID:', userId);

    // Test 1: Vérifier si l'utilisateur existe dans auth.users
    console.log('\n1️⃣ Vérification de l\'utilisateur dans auth.users...');
    const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(userId);

    if (authError) {
        console.log('❌ Erreur auth.users:', authError);
    } else {
        console.log('✅ Utilisateur trouvé dans auth.users:', {
            id: authUser.user.id,
            email: authUser.user.email,
            metadata: authUser.user.user_metadata
        });
    }

    // Test 2: Vérifier si le profil existe dans user_profiles
    console.log('\n2️⃣ Vérification du profil dans user_profiles...');
    const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId);

    if (profileError) {
        console.log('❌ Erreur user_profiles:', profileError);
    } else {
        console.log('📊 Résultat user_profiles:', profile);
        if (profile && profile.length > 0) {
            console.log('✅ Profil trouvé:', profile[0]);
        } else {
            console.log('❌ Aucun profil trouvé');
        }
    }

    // Test 3: Vérifier toutes les lignes de user_profiles
    console.log('\n3️⃣ Vérification de toutes les lignes dans user_profiles...');
    const { data: allProfiles, error: allProfilesError } = await supabase
        .from('user_profiles')
        .select('*');

    if (allProfilesError) {
        console.log('❌ Erreur lors de la récupération de tous les profils:', allProfilesError);
    } else {
        console.log('📊 Tous les profils dans la base:', allProfiles);
        console.log('📈 Nombre total de profils:', allProfiles.length);
    }

    // Test 4: Vérifier les politiques RLS
    console.log('\n4️⃣ Test des politiques RLS...');
    const { data: rlsTest, error: rlsError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .single();

    if (rlsError) {
        console.log('❌ Erreur RLS:', rlsError);
    } else {
        console.log('✅ Test RLS réussi:', rlsTest);
    }
}

testUserProfile().catch(console.error); 