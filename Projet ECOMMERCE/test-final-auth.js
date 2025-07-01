const axios = require('axios');

const API_BASE_URL = 'http://localhost:4000/api';
const TEST_EMAIL = 'test@gmail.com';
const TEST_PASSWORD = 'test123';

async function testFinalAuth() {
    console.log('🧪 Test final de l\'authentification corrigée\n');

    try {
        // Test 1: Connexion normale
        console.log('1️⃣ Test de connexion normale...');
        const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: TEST_EMAIL,
            password: TEST_PASSWORD
        });

        if (loginResponse.status === 200) {
            console.log('✅ Connexion normale réussie');
            const { access_token } = loginResponse.data.session;
            
            // Test de récupération du profil
            const profileResponse = await axios.get(`${API_BASE_URL}/users/me`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`
                }
            });

            if (profileResponse.status === 200) {
                console.log('✅ Profil récupéré avec succès');
                console.log('📋 Profil:', profileResponse.data);
            } else {
                console.log('❌ Erreur profil:', profileResponse.status);
            }
        } else {
            console.log('❌ Erreur connexion normale:', loginResponse.status);
        }

    } catch (error) {
        console.error('❌ Erreur test normal:', error.response?.data || error.message);
    }

    try {
        // Test 2: Connexion dashboard
        console.log('\n2️⃣ Test de connexion dashboard...');
        const dashboardResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: TEST_EMAIL,
            password: TEST_PASSWORD
        }, {
            headers: {
                'x-client-type': 'dashboard'
            }
        });

        if (dashboardResponse.status === 200) {
            console.log('✅ Connexion dashboard réussie');
            const { access_token } = dashboardResponse.data.session;
            
            // Test d'accès aux données vendeur
            const vendorResponse = await axios.get(`${API_BASE_URL}/vendor-analytics/my-dashboard`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`,
                    'x-client-type': 'dashboard'
                }
            });

            if (vendorResponse.status === 200) {
                console.log('✅ Accès vendeur réussi');
                console.log('📊 Données vendeur:', vendorResponse.data);
            } else {
                console.log('❌ Erreur accès vendeur:', vendorResponse.status);
            }
        } else {
            console.log('❌ Erreur connexion dashboard:', dashboardResponse.status);
        }

    } catch (error) {
        console.error('❌ Erreur test dashboard:', error.response?.data || error.message);
    }

    console.log('\n🎯 Test terminé');
}

async function main() {
    console.log('🚀 Test final de l\'authentification\n');
    
    // Attendre que le serveur soit prêt
    console.log('⏳ Attente du serveur...');
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    await testFinalAuth();
}

if (require.main === module) {
    main();
}

module.exports = { testFinalAuth }; 