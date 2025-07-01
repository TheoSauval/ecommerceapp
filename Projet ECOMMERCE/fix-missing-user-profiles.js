const { supabase, supabasePublic } = require('./config/supabase');

async function fixMissingUserProfiles() {
    console.log('🔧 Diagnostic et correction des profils utilisateurs manquants...\n');

    try {
        // 1. Récupérer tous les utilisateurs de auth.users
        console.log('📋 Récupération de tous les utilisateurs auth.users...');
        const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
        
        if (authError) {
            console.error('❌ Erreur lors de la récupération des utilisateurs:', authError);
            return;
        }

        console.log(`✅ ${authUsers.users.length} utilisateurs trouvés dans auth.users`);

        // 2. Récupérer tous les profils existants
        console.log('\n📋 Récupération de tous les profils utilisateurs...');
        const { data: existingProfiles, error: profileError } = await supabase
            .from('user_profiles')
            .select('*');

        if (profileError) {
            console.error('❌ Erreur lors de la récupération des profils:', profileError);
            return;
        }

        console.log(`✅ ${existingProfiles.length} profils trouvés dans user_profiles`);

        // 3. Identifier les utilisateurs sans profil
        const existingProfileIds = existingProfiles.map(p => p.id);
        const usersWithoutProfile = authUsers.users.filter(user => !existingProfileIds.includes(user.id));

        console.log(`\n🔍 ${usersWithoutProfile.length} utilisateurs sans profil identifiés`);

        if (usersWithoutProfile.length === 0) {
            console.log('✅ Tous les utilisateurs ont un profil !');
            return;
        }

        // 4. Créer les profils manquants
        console.log('\n🔧 Création des profils manquants...');
        let createdCount = 0;
        let errorCount = 0;

        for (const user of usersWithoutProfile) {
            try {
                console.log(`\n👤 Traitement de l'utilisateur: ${user.email} (${user.id})`);
                
                // Extraire les métadonnées
                const metadata = user.user_metadata || {};
                const nom = metadata.nom || 'Utilisateur';
                const prenom = metadata.prenom || 'Anonyme';
                const age = metadata.age || 18;
                const role = metadata.role || 'user';

                console.log(`📋 Métadonnées extraites: nom="${nom}", prenom="${prenom}", age=${age}, role="${role}"`);

                // Créer le profil
                const { data: newProfile, error: createError } = await supabase
                    .from('user_profiles')
                    .insert({
                        id: user.id,
                        nom,
                        prenom,
                        age,
                        role
                    })
                    .select()
                    .single();

                if (createError) {
                    console.error(`❌ Erreur lors de la création du profil pour ${user.email}:`, createError);
                    errorCount++;
                } else {
                    console.log(`✅ Profil créé avec succès pour ${user.email}:`, newProfile);
                    createdCount++;
                }

            } catch (error) {
                console.error(`❌ Erreur lors du traitement de ${user.email}:`, error);
                errorCount++;
            }
        }

        // 5. Résumé
        console.log('\n📊 Résumé de l\'opération:');
        console.log(`✅ Profils créés: ${createdCount}`);
        console.log(`❌ Erreurs: ${errorCount}`);
        console.log(`📋 Total utilisateurs traités: ${usersWithoutProfile.length}`);

        // 6. Vérification finale
        console.log('\n🔍 Vérification finale...');
        const { data: finalProfiles, error: finalError } = await supabase
            .from('user_profiles')
            .select('*');

        if (finalError) {
            console.error('❌ Erreur lors de la vérification finale:', finalError);
        } else {
            console.log(`✅ Total de profils après correction: ${finalProfiles.length}`);
            
            if (finalProfiles.length === authUsers.users.length) {
                console.log('🎉 Tous les utilisateurs ont maintenant un profil !');
            } else {
                console.log('⚠️  Il reste encore des utilisateurs sans profil');
            }
        }

    } catch (error) {
        console.error('❌ Erreur générale:', error);
    }
}

// Fonction pour vérifier un utilisateur spécifique
async function checkSpecificUser(userId) {
    console.log(`🔍 Vérification de l'utilisateur spécifique: ${userId}\n`);

    try {
        // 1. Vérifier dans auth.users
        const { data: { user }, error: authError } = await supabase.auth.admin.getUserById(userId);
        
        if (authError) {
            console.error('❌ Erreur auth.users:', authError);
            return;
        }

        console.log('✅ Utilisateur trouvé dans auth.users:', {
            id: user.id,
            email: user.email,
            metadata: user.user_metadata
        });

        // 2. Vérifier dans user_profiles
        const { data: profile, error: profileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();

        if (profileError) {
            if (profileError.code === 'PGRST116') {
                console.log('❌ Profil manquant dans user_profiles');
                
                // Créer le profil manquant
                const metadata = user.user_metadata || {};
                const { data: newProfile, error: createError } = await supabase
                    .from('user_profiles')
                    .insert({
                        id: userId,
                        nom: metadata.nom || 'Utilisateur',
                        prenom: metadata.prenom || 'Anonyme',
                        age: metadata.age || 18,
                        role: metadata.role || 'user'
                    })
                    .select()
                    .single();

                if (createError) {
                    console.error('❌ Erreur lors de la création du profil:', createError);
                } else {
                    console.log('✅ Profil créé avec succès:', newProfile);
                }
            } else {
                console.error('❌ Erreur user_profiles:', profileError);
            }
        } else {
            console.log('✅ Profil trouvé dans user_profiles:', profile);
        }

    } catch (error) {
        console.error('❌ Erreur:', error);
    }
}

// Fonction pour vérifier le trigger
async function checkTrigger() {
    console.log('🔧 Vérification du trigger handle_new_user...\n');

    try {
        // Vérifier si le trigger existe
        const { data: triggers, error: triggerError } = await supabase
            .rpc('get_triggers_info');

        if (triggerError) {
            console.log('⚠️  Impossible de vérifier les triggers directement');
            
            // Test manuel du trigger
            console.log('🧪 Test manuel du trigger...');
            
            // Créer un utilisateur de test
            const testEmail = `test-${Date.now()}@example.com`;
            const { data: testUser, error: createError } = await supabase.auth.admin.createUser({
                email: testEmail,
                password: 'testpassword123',
                email_confirm: true,
                user_metadata: {
                    nom: 'Test',
                    prenom: 'User',
                    age: 25,
                    role: 'user'
                }
            });

            if (createError) {
                console.error('❌ Erreur lors de la création de l\'utilisateur de test:', createError);
                return;
            }

            console.log('✅ Utilisateur de test créé:', testUser.user.id);

            // Attendre un peu pour que le trigger s'exécute
            await new Promise(resolve => setTimeout(resolve, 1000));

            // Vérifier si le profil a été créé
            const { data: testProfile, error: profileError } = await supabase
                .from('user_profiles')
                .select('*')
                .eq('id', testUser.user.id)
                .single();

            if (profileError) {
                console.log('❌ Le trigger ne fonctionne pas - profil non créé automatiquement');
                
                // Créer le profil manuellement
                const { data: manualProfile, error: manualError } = await supabase
                    .from('user_profiles')
                    .insert({
                        id: testUser.user.id,
                        nom: 'Test',
                        prenom: 'User',
                        age: 25,
                        role: 'user'
                    })
                    .select()
                    .single();

                if (manualError) {
                    console.error('❌ Erreur lors de la création manuelle:', manualError);
                } else {
                    console.log('✅ Profil créé manuellement:', manualProfile);
                }
            } else {
                console.log('✅ Le trigger fonctionne - profil créé automatiquement:', testProfile);
            }

            // Nettoyer l'utilisateur de test
            await supabase.auth.admin.deleteUser(testUser.user.id);
            console.log('🧹 Utilisateur de test supprimé');

        } else {
            console.log('📋 Triggers trouvés:', triggers);
        }

    } catch (error) {
        console.error('❌ Erreur lors de la vérification du trigger:', error);
    }
}

// Exécuter les fonctions selon les arguments
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('🔧 Script de correction des profils utilisateurs manquants');
        console.log('Usage:');
        console.log('  node fix-missing-user-profiles.js                    # Corriger tous les profils manquants');
        console.log('  node fix-missing-user-profiles.js check <userId>     # Vérifier un utilisateur spécifique');
        console.log('  node fix-missing-user-profiles.js trigger            # Vérifier le trigger');
        return;
    }

    const command = args[0];

    switch (command) {
        case 'check':
            if (args[1]) {
                await checkSpecificUser(args[1]);
            } else {
                console.log('❌ Veuillez spécifier un userId');
            }
            break;
        case 'trigger':
            await checkTrigger();
            break;
        default:
            await fixMissingUserProfiles();
    }
}

// Exécuter si le script est appelé directement
if (require.main === module) {
    main();
}

module.exports = {
    fixMissingUserProfiles,
    checkSpecificUser,
    checkTrigger
}; 