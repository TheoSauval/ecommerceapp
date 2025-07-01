const axios = require('axios');

const API_URL = 'http://localhost:4000/api';

// Test de gestion des sessions multiples
async function testMultipleSessions() {
    console.log('🧪 Test de gestion des sessions multiples...\n');

    try {
        // 1. Connexion utilisateur 1 (simulation app mobile)
        console.log('📱 Connexion utilisateur 1 (app mobile)...');
        const user1Response = await axios.post(`${API_URL}/auth/login`, {
            mail: 'user@example.com',
            password: 'password123'
        });
        
        const user1Token = user1Response.data.session.access_token;
        console.log('✅ Utilisateur 1 connecté, token:', user1Token.substring(0, 20) + '...');

        // 2. Connexion utilisateur 2 (simulation dashboard)
        console.log('\n💻 Connexion utilisateur 2 (dashboard)...');
        const user2Response = await axios.post(`${API_URL}/auth/login`, {
            mail: 'vendor@example.com',
            password: 'password123'
        });
        
        const user2Token = user2Response.data.session.access_token;
        console.log('✅ Utilisateur 2 connecté, token:', user2Token.substring(0, 20) + '...');

        // 3. Vérifier que les deux tokens sont différents
        if (user1Token !== user2Token) {
            console.log('✅ Tokens différents - Sessions multiples fonctionnent');
        } else {
            console.log('❌ Tokens identiques - Problème de sessions multiples');
        }

        // 4. Tester l'accès avec le token utilisateur 1
        console.log('\n🔍 Test accès avec token utilisateur 1...');
        try {
            const user1Profile = await axios.get(`${API_URL}/auth/profile`, {
                headers: { Authorization: `Bearer ${user1Token}` }
            });
            console.log('✅ Accès utilisateur 1 réussi:', user1Profile.data.user.email);
        } catch (error) {
            console.log('❌ Échec accès utilisateur 1:', error.response?.data?.message);
        }

        // 5. Tester l'accès avec le token utilisateur 2
        console.log('\n🔍 Test accès avec token utilisateur 2...');
        try {
            const user2Profile = await axios.get(`${API_URL}/auth/profile`, {
                headers: { Authorization: `Bearer ${user2Token}` }
            });
            console.log('✅ Accès utilisateur 2 réussi:', user2Profile.data.user.email);
        } catch (error) {
            console.log('❌ Échec accès utilisateur 2:', error.response?.data?.message);
        }

        // 6. Déconnexion utilisateur 1
        console.log('\n🚪 Déconnexion utilisateur 1...');
        try {
            await axios.post(`${API_URL}/auth/logout`, {}, {
                headers: { Authorization: `Bearer ${user1Token}` }
            });
            console.log('✅ Déconnexion utilisateur 1 réussie');
        } catch (error) {
            console.log('❌ Échec déconnexion utilisateur 1:', error.response?.data?.message);
        }

        // 7. Vérifier que l'utilisateur 2 est toujours connecté
        console.log('\n🔍 Vérification que l\'utilisateur 2 est toujours connecté...');
        try {
            const user2ProfileAfter = await axios.get(`${API_URL}/auth/profile`, {
                headers: { Authorization: `Bearer ${user2Token}` }
            });
            console.log('✅ Utilisateur 2 toujours connecté:', user2ProfileAfter.data.user.email);
        } catch (error) {
            console.log('❌ Utilisateur 2 déconnecté par erreur:', error.response?.data?.message);
        }

        console.log('\n🎉 Test terminé avec succès !');

    } catch (error) {
        console.error('❌ Erreur lors du test:', error.response?.data || error.message);
    }
}

// Test de rafraîchissement de token
async function testTokenRefresh() {
    console.log('\n🔄 Test de rafraîchissement de token...\n');

    try {
        // 1. Connexion
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            mail: 'user@example.com',
            password: 'password123'
        });
        
        const refreshToken = loginResponse.data.session.refresh_token;
        console.log('✅ Connexion réussie, refresh token obtenu');

        // 2. Rafraîchir le token
        const refreshResponse = await axios.post(`${API_URL}/auth/refresh`, {
            refresh_token: refreshToken
        });
        
        const newAccessToken = refreshResponse.data.session.access_token;
        console.log('✅ Token rafraîchi avec succès');

        // 3. Tester le nouveau token
        const profileResponse = await axios.get(`${API_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${newAccessToken}` }
        });
        
        console.log('✅ Nouveau token fonctionne:', profileResponse.data.user.email);

    } catch (error) {
        console.error('❌ Erreur lors du test de rafraîchissement:', error.response?.data || error.message);
    }
}

// Exécuter les tests
async function runTests() {
    console.log('🚀 Démarrage des tests de gestion des sessions...\n');
    
    await testMultipleSessions();
    await testTokenRefresh();
    
    console.log('\n✨ Tous les tests terminés !');
}

// Exécuter si le script est appelé directement
if (require.main === module) {
    runTests();
}

module.exports = {
    testMultipleSessions,
    testTokenRefresh
}; 