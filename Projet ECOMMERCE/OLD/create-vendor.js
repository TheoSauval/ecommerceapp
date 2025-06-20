// Script pour créer un utilisateur vendeur de test
require('dotenv').config();
const { supabasePublic } = require('./config/supabase');

async function createVendorUser() {
    try {
        console.log('Création d\'un utilisateur vendeur de test...');
        
        // 1. Créer un utilisateur vendeur dans Supabase Auth
        const { data: authData, error: authError } = await supabasePublic.auth.signUp({
            email: 'vendor@test.com',
            password: 'password123',
            options: {
                data: {
                    nom: 'Vendeur',
                    prenom: 'Test',
                    age: 30,
                    role: 'vendor'
                }
            }
        });
        
        if (authError) {
            console.error('Erreur lors de la création de l\'utilisateur vendeur:', authError);
            return;
        }
        
        console.log('Utilisateur vendeur créé:', authData.user);
        
        // 2. Créer un profil vendeur
        const { data: vendorData, error: vendorError } = await supabasePublic
            .from('vendors')
            .insert({
                nom: 'Boutique Vendeur Test',
                user_id: authData.user.id
            })
            .select()
            .single();
            
        if (vendorError) {
            console.error('Erreur lors de la création du profil vendeur:', vendorError);
            return;
        }
        
        console.log('Profil vendeur créé:', vendorData);
        
        // 3. Se connecter pour obtenir le token
        const { data: loginData, error: loginError } = await supabasePublic.auth.signInWithPassword({
            email: 'vendor@test.com',
            password: 'password123'
        });
        
        if (loginError) {
            console.error('Erreur lors de la connexion:', loginError);
            return;
        }
        
        console.log('Connexion réussie!');
        console.log('Token d\'accès:', loginData.session.access_token);
        console.log('Utilisez ce token dans votre dashboard admin');
        console.log('');
        console.log('Identifiants de connexion:');
        console.log('Email: vendor@test.com');
        console.log('Mot de passe: password123');
        
    } catch (error) {
        console.error('Erreur générale:', error);
    }
}

// Exécuter le script
if (require.main === module) {
    createVendorUser();
}

module.exports = { createVendorUser }; 