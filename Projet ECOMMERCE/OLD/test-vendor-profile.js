// Script pour vérifier et créer le profil vendeur manquant
require('dotenv').config();
const { supabasePublic } = require('./config/supabase');

async function checkAndCreateVendorProfile() {
    try {
        // Token de l'utilisateur connecté
        const token = 'eyJhbGciOiJIUzI1NiIsImtpZCI6ImV1SCtYM1gxOEJvcUpEZGciLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL290dG5wbW13b2Ftem9yemVocm5rLnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI1ZjQ2ODAyNi1hMTI2LTQ3YjMtOWMzZi03OTliYmNmNTZhNTgiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzUwNDU4NzY3LCJpYXQiOjE3NTA0NTUxNjcsImVtYWlsIjoidGVzdEBjYWNhLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiYWdlIjoxOCwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5vbSI6ImNhY2EiLCJwcmVub20iOiJDYWNhIiwicm9sZSI6InZlbmRvciJ9LCJyb2xlIjoiYXV0aGVudGljYXRlZCIsImFhbCI6ImFhbDEiLCJhbXIiOlt7Im1ldGhvZCI6InBhc3N3b3JkIiwidGltZXN0YW1wIjoxNzUwNDU1MTY3fV0sInNlc3Npb25faWQiOiIzZmVjMTdkOC1iMTYyLTRkYjAtOWQzOS1jN2JiZmE3Y2MwNDQiLCJpc19hbm9ueW1vdXMiOmZhbHNlfQ.p9OwKhWEA3pnaBU_W261SIhTkzRfG7o7gmvA_hh0yFQ';
        
        console.log('Vérification du profil utilisateur...');
        
        // 1. Vérifier l'utilisateur avec le token
        const { data: { user }, error: userError } = await supabasePublic.auth.getUser(token);
        
        if (userError) {
            console.error('Erreur lors de la vérification de l\'utilisateur:', userError);
            return;
        }
        
        console.log('Utilisateur trouvé:', user);
        console.log('ID utilisateur:', user.id);
        
        // 2. Vérifier le profil utilisateur
        const { data: profile, error: profileError } = await supabasePublic
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
            
        if (profileError) {
            console.error('Erreur lors de la récupération du profil:', profileError);
            return;
        }
        
        console.log('Profil utilisateur:', profile);
        
        // 3. Vérifier s'il existe déjà un profil vendeur
        const { data: existingVendor, error: vendorCheckError } = await supabasePublic
            .from('vendors')
            .select('*')
            .eq('user_id', user.id)
            .single();
            
        if (vendorCheckError && vendorCheckError.code !== 'PGRST116') {
            console.error('Erreur lors de la vérification du vendeur:', vendorCheckError);
            return;
        }
        
        if (existingVendor) {
            console.log('Profil vendeur existant:', existingVendor);
            return;
        }
        
        // 4. Créer le profil vendeur manquant
        console.log('Création du profil vendeur manquant...');
        
        const { data: newVendor, error: createVendorError } = await supabasePublic
            .from('vendors')
            .insert({
                nom: `${profile.prenom} ${profile.nom} - Boutique`,
                user_id: user.id
            })
            .select()
            .single();
            
        if (createVendorError) {
            console.error('Erreur lors de la création du profil vendeur:', createVendorError);
            return;
        }
        
        console.log('Profil vendeur créé avec succès:', newVendor);
        console.log('Vous pouvez maintenant ajouter des produits !');
        
    } catch (error) {
        console.error('Erreur générale:', error);
    }
}

// Exécuter le script
if (require.main === module) {
    checkAndCreateVendorProfile();
}

module.exports = { checkAndCreateVendorProfile }; 