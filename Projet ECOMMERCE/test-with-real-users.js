const { supabase } = require('./config/supabase');
const axios = require('axios');

const API_BASE_URL = 'http://localhost:4000/api';

async function getRealUsers() {
    console.log('🔍 Récupération des vrais utilisateurs...\n');
    
    try {
        const { data: { users }, error } = await supabase.auth.admin.listUsers();
        
        if (error) {
            console.error('❌ Erreur:', error);
            return [];
        }
        
        console.log(`✅ ${users.length} utilisateurs trouvés:`);
        users.forEach((user, index) => {
            console.log(`${index + 1}. ${user.email} (${user.user_metadata?.role || 'user'})`);
        });
        
        return users;
    } catch (error) {
        console.error('❌ Erreur:', error);
        return [];
    }
}

async function testUserLogin(email, password) {
    console.log(`\n🧪 Test de connexion pour ${email}...`);
    
    try {
        const response = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: email,
            password: password
        });

        if (response.status === 200) {
            console.log('✅ Connexion réussie');
            const { access_token } = response.data.session;
            
            // Test de récupération du profil
            const profileResponse = await axios.get(`${API_BASE_URL}/users/me`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`
                }
            });

            if (profileResponse.status === 200) {
                console.log('✅ Profil récupéré avec succès');
                console.log('📋 Profil:', profileResponse.data);
                return true;
            } else {
                console.log('❌ Erreur profil:', profileResponse.status);
                return false;
            }
        } else {
            console.log('❌ Erreur connexion:', response.status);
            return false;
        }
    } catch (error) {
        console.error('❌ Erreur:', error.response?.data || error.message);
        return false;
    }
}

async function testDashboardLogin(email, password) {
    console.log(`\n🖥️ Test dashboard pour ${email}...`);
    
    try {
        const response = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: email,
            password: password
        }, {
            headers: {
                'x-client-type': 'dashboard'
            }
        });

        if (response.status === 200) {
            console.log('✅ Connexion dashboard réussie');
            const { access_token } = response.data.session;
            
            // Test d'accès aux données vendeur
            const vendorResponse = await axios.get(`${API_BASE_URL}/vendor-analytics/my-dashboard`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`,
                    'x-client-type': 'dashboard'
                }
            });

            if (vendorResponse.status === 200) {
                console.log('✅ Accès vendeur réussi');
                return true;
            } else {
                console.log('❌ Erreur accès vendeur:', vendorResponse.status);
                return false;
            }
        } else {
            console.log('❌ Erreur connexion dashboard:', response.status);
            return false;
        }
    } catch (error) {
        console.error('❌ Erreur dashboard:', error.response?.data || error.message);
        return false;
    }
}

async function main() {
    console.log('🚀 Test avec les vrais utilisateurs\n');
    
    // Récupérer les utilisateurs
    const users = await getRealUsers();
    
    if (users.length === 0) {
        console.log('❌ Aucun utilisateur trouvé');
        return;
    }
    
    // Tester avec le premier utilisateur (probablement un vendeur)
    const testUser = users.find(u => u.user_metadata?.role === 'vendor') || users[0];
    
    console.log(`\n🎯 Test avec l'utilisateur: ${testUser.email}`);
    
    // Test de connexion normale
    const loginSuccess = await testUserLogin(testUser.email, 'password123');
    
    // Test de connexion dashboard
    const dashboardSuccess = await testDashboardLogin(testUser.email, 'password123');
    
    console.log('\n📊 RÉSULTATS:');
    console.log(`✅ Connexion normale: ${loginSuccess ? 'RÉUSSI' : 'ÉCHOUÉ'}`);
    console.log(`✅ Connexion dashboard: ${dashboardSuccess ? 'RÉUSSI' : 'ÉCHOUÉ'}`);
    
    if (loginSuccess && dashboardSuccess) {
        console.log('\n🎉 TOUS LES TESTS SONT RÉUSSIS !');
        console.log('💡 Le problème d\'authentification est résolu');
    } else {
        console.log('\n⚠️ Certains tests ont échoué');
        console.log('💡 Vérifiez les logs pour plus de détails');
    }
}

if (require.main === module) {
    main();
}

module.exports = {
    getRealUsers,
    testUserLogin,
    testDashboardLogin
}; 