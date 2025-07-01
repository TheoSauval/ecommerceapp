const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000/api';

// Configuration pour les tests
const testUser = {
    email: `test-change-password-${Date.now()}@example.com`,
    password: 'password123',
    nom: 'Test',
    prenom: 'User',
    age: 25
};

let authToken = null;

async function testChangePassword() {
    console.log('🧪 Test de la fonctionnalité de changement de mot de passe\n');

    try {
        // 1. Créer un utilisateur de test
        console.log('1️⃣ Création d\'un utilisateur de test...');
        const registerResponse = await axios.post(`${API_BASE_URL}/auth/register`, testUser);
        console.log('✅ Utilisateur créé:', registerResponse.data.user.email);

        // 2. Se connecter pour obtenir un token
        console.log('\n2️⃣ Connexion de l\'utilisateur...');
        const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: testUser.email,
            password: testUser.password
        });
        
        authToken = loginResponse.data.session.access_token;
        console.log('✅ Connexion réussie, token obtenu');

        // 3. Tester le changement de mot de passe
        console.log('\n3️⃣ Test du changement de mot de passe...');
        const newPassword = 'newPassword456!';
        
        const changePasswordResponse = await axios.put(`${API_BASE_URL}/auth/change-password`, {
            oldPassword: testUser.password,
            newPassword: newPassword
        }, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        console.log('✅ Mot de passe changé avec succès:', changePasswordResponse.data.message);

        // 4. Vérifier que le nouveau mot de passe fonctionne
        console.log('\n4️⃣ Vérification du nouveau mot de passe...');
        const newLoginResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            mail: testUser.email,
            password: newPassword
        });
        
        console.log('✅ Connexion avec le nouveau mot de passe réussie');

        // 5. Tester les cas d'erreur
        console.log('\n5️⃣ Test des cas d\'erreur...');
        
        // Test avec ancien mot de passe incorrect
        try {
            await axios.put(`${API_BASE_URL}/auth/change-password`, {
                oldPassword: 'wrongPassword',
                newPassword: 'anotherPassword123'
            }, {
                headers: {
                    'Authorization': `Bearer ${authToken}`
                }
            });
            console.log('❌ Erreur: Le changement avec un mauvais mot de passe aurait dû échouer');
        } catch (error) {
            if (error.response?.status === 400) {
                console.log('✅ Erreur correctement gérée: Ancien mot de passe incorrect');
            } else {
                console.log('❌ Erreur inattendue:', error.response?.data?.message);
            }
        }

        // Test avec mot de passe trop court
        try {
            await axios.put(`${API_BASE_URL}/auth/change-password`, {
                oldPassword: newPassword,
                newPassword: '123'
            }, {
                headers: {
                    'Authorization': `Bearer ${authToken}`
                }
            });
            console.log('❌ Erreur: Le changement avec un mot de passe trop court aurait dû échouer');
        } catch (error) {
            if (error.response?.status === 400) {
                console.log('✅ Erreur correctement gérée: Mot de passe trop court');
            } else {
                console.log('❌ Erreur inattendue:', error.response?.data?.message);
            }
        }

        // Test avec le même mot de passe
        try {
            await axios.put(`${API_BASE_URL}/auth/change-password`, {
                oldPassword: newPassword,
                newPassword: newPassword
            }, {
                headers: {
                    'Authorization': `Bearer ${authToken}`
                }
            });
            console.log('❌ Erreur: Le changement avec le même mot de passe aurait dû échouer');
        } catch (error) {
            if (error.response?.status === 400) {
                console.log('✅ Erreur correctement gérée: Nouveau mot de passe identique à l\'ancien');
            } else {
                console.log('❌ Erreur inattendue:', error.response?.data?.message);
            }
        }

        console.log('\n🎉 Tous les tests de changement de mot de passe sont passés !');

    } catch (error) {
        console.error('❌ Erreur lors du test:', error.response?.data?.message || error.message);
        process.exit(1);
    }
}

// Lancer les tests
testChangePassword(); 