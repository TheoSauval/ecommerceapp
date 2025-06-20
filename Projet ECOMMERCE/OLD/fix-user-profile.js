// Script pour créer le profil utilisateur manquant
require('dotenv').config();
const { supabasePublic } = require('./config/supabase');

async function fixUserProfile() {
    try {
        // ID de l'utilisateur depuis le token
        const userId = '5f468026-a126-47b3-9c3f-799bbcf56a58';
        
        console.log('🔍 Vérification de l\'utilisateur...');
        
        // 1. Vérifier si l'utilisateur existe dans auth.users
        const { data: { user }, error: userError } = await supabasePublic.auth.admin.getUserById(userId);
        
        if (userError) {
            console.error('❌ Erreur lors de la récupération de l\'utilisateur:', userError);
            return;
        }
        
        console.log('✅ Utilisateur trouvé:', user.email);
        console.log('📋 Métadonnées:', user.user_metadata);
        
        // 2. Vérifier si le profil existe déjà
        const { data: existingProfile, error: profileCheckError } = await supabasePublic
            .from('user_profiles')
            .select('*')
            .eq('id', userId)
            .single();
            
        if (profileCheckError && profileCheckError.code !== 'PGRST116') {
            console.error('❌ Erreur lors de la vérification du profil:', profileCheckError);
            return;
        }
        
        if (existingProfile) {
            console.log('✅ Profil existant:', existingProfile);
            return;
        }
        
        // 3. Créer le profil utilisateur manquant
        console.log('🔧 Création du profil utilisateur...');
        
        const { data: newProfile, error: createProfileError } = await supabasePublic
            .from('user_profiles')
            .insert({
                id: userId,
                nom: user.user_metadata?.nom || 'Caca',
                prenom: user.user_metadata?.prenom || 'Caca',
                age: user.user_metadata?.age || 18,
                role: user.user_metadata?.role || 'vendor'
            })
            .select()
            .single();
            
        if (createProfileError) {
            console.error('❌ Erreur lors de la création du profil:', createProfileError);
            return;
        }
        
        console.log('✅ Profil créé avec succès:', newProfile);
        
        // 4. Vérifier s'il existe un profil vendeur
        const { data: existingVendor, error: vendorCheckError } = await supabasePublic
            .from('vendors')
            .select('*')
            .eq('user_id', userId)
            .single();
            
        if (vendorCheckError && vendorCheckError.code !== 'PGRST116') {
            console.error('❌ Erreur lors de la vérification du vendeur:', vendorCheckError);
            return;
        }
        
        if (existingVendor) {
            console.log('✅ Profil vendeur existant:', existingVendor);
        } else {
            // 5. Créer le profil vendeur
            console.log('🔧 Création du profil vendeur...');
            
            const { data: newVendor, error: createVendorError } = await supabasePublic
                .from('vendors')
                .insert({
                    nom: `${newProfile.prenom} ${newProfile.nom} - Boutique`,
                    user_id: userId
                })
                .select()
                .single();
                
            if (createVendorError) {
                console.error('❌ Erreur lors de la création du vendeur:', createVendorError);
                return;
            }
            
            console.log('✅ Profil vendeur créé avec succès:', newVendor);
        }
        
        console.log('🎉 Profils créés avec succès ! Vous pouvez maintenant utiliser le dashboard admin.');
        
    } catch (error) {
        console.error('❌ Erreur générale:', error);
    }
}

// Exécuter le script
if (require.main === module) {
    fixUserProfile();
}

module.exports = { fixUserProfile }; 