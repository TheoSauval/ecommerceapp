const axios = require('axios');

// Configuration pour les tests
const API_BASE_URL = 'http://localhost:4000/api';
const TEST_USER_EMAIL = 'test@user.com';
const TEST_USER_PASSWORD = 'password123';

async function testAuthFix() {
    console.log('🧪 Test de la correction d\'authentification\n');

    try {
        // Test 1: Connexion utilisateur
        console.log('1️⃣ Test de connexion...');
        const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: TEST_USER_EMAIL,
            password: TEST_USER_PASSWORD
        });

        if (loginResponse.status === 200) {
            console.log('✅ Connexion réussie');
            const { access_token, user } = loginResponse.data.session;
            console.log('👤 Utilisateur connecté:', user.email);
            console.log('🔑 Token reçu:', access_token ? 'Oui' : 'Non');
            
            // Test 2: Récupération du profil utilisateur
            console.log('\n2️⃣ Test de récupération du profil...');
            const profileResponse = await axios.get(`${API_BASE_URL}/users/me`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`
                }
            });

            if (profileResponse.status === 200) {
                console.log('✅ Profil récupéré avec succès');
                console.log('📋 Données du profil:', profileResponse.data);
            } else {
                console.log('❌ Erreur lors de la récupération du profil:', profileResponse.status);
            }

            // Test 3: Test avec header x-client-type (dashboard)
            console.log('\n3️⃣ Test avec header x-client-type (dashboard)...');
            const dashboardResponse = await axios.get(`${API_BASE_URL}/users/me`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`,
                    'x-client-type': 'dashboard'
                }
            });

            if (dashboardResponse.status === 200) {
                console.log('✅ Test dashboard réussi');
            } else {
                console.log('❌ Erreur test dashboard:', dashboardResponse.status);
            }

        } else {
            console.log('❌ Erreur de connexion:', loginResponse.status);
        }

    } catch (error) {
        console.error('❌ Erreur lors du test:', error.response?.data || error.message);
        
        if (error.response?.status === 401) {
            console.log('💡 Erreur 401 - Vérifiez que le serveur est démarré et que les identifiants sont corrects');
        }
    }
}

async function testDashboardLogin() {
    console.log('\n🖥️ Test de connexion dashboard\n');

    try {
        // Test de connexion avec header x-client-type
        const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: 'enzovendeur@test.com',
            password: 'password123'
        }, {
            headers: {
                'x-client-type': 'dashboard'
            }
        });

        if (loginResponse.status === 200) {
            console.log('✅ Connexion dashboard réussie');
            const { access_token } = loginResponse.data.session;
            
            // Test d'accès aux données vendeur
            const vendorResponse = await axios.get(`${API_BASE_URL}/vendor-analytics/my-dashboard`, {
                headers: {
                    'Authorization': `Bearer ${access_token}`,
                    'x-client-type': 'dashboard'
                }
            });

            if (vendorResponse.status === 200) {
                console.log('✅ Accès aux données vendeur réussi');
            } else {
                console.log('❌ Erreur accès vendeur:', vendorResponse.status);
            }
        } else {
            console.log('❌ Erreur connexion dashboard:', loginResponse.status);
        }

    } catch (error) {
        console.error('❌ Erreur test dashboard:', error.response?.data || error.message);
    }
}

async function main() {
    console.log('🚀 Démarrage des tests d\'authentification...\n');
    
    // Attendre que le serveur soit prêt
    console.log('⏳ Attente du démarrage du serveur...');
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    await testAuthFix();
    await testDashboardLogin();
    
    console.log('\n✅ Tests terminés');
}

if (require.main === module) {
    main();
}

module.exports = {
    testAuthFix,
    testDashboardLogin
}; 