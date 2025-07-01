const { supabase } = require('./config/supabase');

async function resetUserPassword(email, newPassword) {
    console.log(`🔧 Réinitialisation du mot de passe pour ${email}...\n`);
    
    try {
        // 1. Trouver l'utilisateur
        const { data: { users }, error: findError } = await supabase.auth.admin.listUsers();
        
        if (findError) {
            console.error('❌ Erreur lors de la recherche:', findError);
            return false;
        }
        
        const user = users.find(u => u.email === email);
        if (!user) {
            console.error(`❌ Utilisateur ${email} non trouvé`);
            return false;
        }
        
        console.log(`✅ Utilisateur trouvé: ${user.email} (ID: ${user.id})`);
        
        // 2. Mettre à jour le mot de passe
        const { data, error: updateError } = await supabase.auth.admin.updateUserById(
            user.id,
            { password: newPassword }
        );
        
        if (updateError) {
            console.error('❌ Erreur lors de la mise à jour:', updateError);
            return false;
        }
        
        console.log('✅ Mot de passe mis à jour avec succès');
        console.log(`📧 Email: ${data.user.email}`);
        console.log(`🔑 Nouveau mot de passe: ${newPassword}`);
        
        return true;
        
    } catch (error) {
        console.error('❌ Erreur:', error);
        return false;
    }
}

async function testUserCredentials(email, password) {
    console.log(`\n🧪 Test des identifiants pour ${email}...`);
    
    try {
        // Test direct avec Supabase
        const { data, error } = await supabase.auth.signInWithPassword({
            email: email,
            password: password
        });
        
        if (error) {
            console.log('❌ Erreur de connexion:', error.message);
            return false;
        }
        
        console.log('✅ Connexion réussie avec Supabase');
        console.log('👤 Utilisateur:', data.user.email);
        console.log('🔑 Session valide:', !!data.session);
        
        // Déconnexion
        await supabase.auth.signOut();
        
        return true;
        
    } catch (error) {
        console.error('❌ Erreur lors du test:', error);
        return false;
    }
}

async function main() {
    const testEmail = 'test@gmail.com';
    const newPassword = 'test123';
    
    console.log('🚀 Réinitialisation du mot de passe utilisateur\n');
    
    // Réinitialiser le mot de passe
    const resetSuccess = await resetUserPassword(testEmail, newPassword);
    
    if (resetSuccess) {
        // Tester les nouveaux identifiants
        const testSuccess = await testUserCredentials(testEmail, newPassword);
        
        if (testSuccess) {
            console.log('\n🎉 SUCCÈS !');
            console.log(`📧 Email: ${testEmail}`);
            console.log(`🔑 Mot de passe: ${newPassword}`);
            console.log('\n💡 Vous pouvez maintenant tester la connexion avec ces identifiants');
        } else {
            console.log('\n⚠️ Le mot de passe a été mis à jour mais le test a échoué');
        }
    } else {
        console.log('\n❌ Échec de la réinitialisation');
    }
}

if (require.main === module) {
    main();
}

module.exports = {
    resetUserPassword,
    testUserCredentials
}; 