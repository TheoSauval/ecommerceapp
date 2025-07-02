const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testCategoriesAPI() {
    console.log('🧪 Test de l\'API des catégories...\n');
    
    try {
        // Test 1: Récupérer les catégories disponibles
        console.log('1️⃣ Test GET /api/products/categories');
        const categoriesResponse = await axios.get(`${BASE_URL}/products/categories`);
        console.log('✅ Succès!');
        console.log('📋 Catégories récupérées:', categoriesResponse.data);
        console.log('📊 Nombre de catégories:', categoriesResponse.data.length);
        console.log('');
        
        // Test 2: Tester le filtrage par catégorie pour chaque catégorie
        console.log('2️⃣ Test du filtrage par catégorie');
        for (const category of categoriesResponse.data) {
            try {
                console.log(`   Test pour la catégorie: "${category}"`);
                const productsResponse = await axios.get(`${BASE_URL}/products/category/${encodeURIComponent(category)}?page=1&limit=5`);
                
                console.log(`   ✅ ${productsResponse.data.products.length} produits trouvés`);
                console.log(`   📄 Page ${productsResponse.data.currentPage} sur ${productsResponse.data.totalPages}`);
                
                if (productsResponse.data.products.length > 0) {
                    console.log(`   🏷️  Exemple de produit: ${productsResponse.data.products[0].nom}`);
                }
                console.log('');
            } catch (error) {
                console.log(`   ❌ Erreur pour "${category}":`, error.response?.data?.message || error.message);
                console.log('');
            }
        }
        
        // Test 3: Tester la pagination
        console.log('3️⃣ Test de la pagination');
        if (categoriesResponse.data.length > 0) {
            const firstCategory = categoriesResponse.data[0];
            console.log(`   Test pagination pour: "${firstCategory}"`);
            
            const page1Response = await axios.get(`${BASE_URL}/products/category/${encodeURIComponent(firstCategory)}?page=1&limit=2`);
            const page2Response = await axios.get(`${BASE_URL}/products/category/${encodeURIComponent(firstCategory)}?page=2&limit=2`);
            
            console.log(`   📄 Page 1: ${page1Response.data.products.length} produits`);
            console.log(`   📄 Page 2: ${page2Response.data.products.length} produits`);
            console.log(`   📊 Total pages: ${page1Response.data.totalPages}`);
            console.log('');
        }
        
        // Test 4: Tester avec une catégorie inexistante
        console.log('4️⃣ Test avec une catégorie inexistante');
        try {
            await axios.get(`${BASE_URL}/products/category/CategorieInexistante?page=1&limit=5`);
            console.log('   ⚠️  Catégorie inexistante retourne des données (normal si aucun produit)');
        } catch (error) {
            console.log('   ✅ Erreur attendue pour catégorie inexistante:', error.response?.status);
        }
        console.log('');
        
        // Test 5: Vérifier la structure des données
        console.log('5️⃣ Vérification de la structure des données');
        if (categoriesResponse.data.length > 0) {
            const firstCategory = categoriesResponse.data[0];
            const productsResponse = await axios.get(`${BASE_URL}/products/category/${encodeURIComponent(firstCategory)}?page=1&limit=1`);
            
            if (productsResponse.data.products.length > 0) {
                const product = productsResponse.data.products[0];
                console.log('   ✅ Structure du produit:');
                console.log(`      - ID: ${product.id}`);
                console.log(`      - Nom: ${product.nom}`);
                console.log(`      - Prix: ${product.prix_base}`);
                console.log(`      - Catégorie: ${product.categorie}`);
                console.log(`      - Variantes: ${product.variants?.length || 0}`);
            }
        }
        
        console.log('\n🎉 Tous les tests sont terminés!');
        
    } catch (error) {
        console.error('❌ Erreur lors du test:', error.response?.data || error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.log('\n💡 Le serveur n\'est pas démarré. Démarrez-le avec:');
            console.log('   npm start');
        }
    }
}

// Fonction pour vérifier la base de données
async function checkDatabase() {
    console.log('🔍 Vérification de la base de données...\n');
    
    try {
        // Test de connexion à l'API
        const response = await axios.get(`${BASE_URL}/products?page=1&limit=1`);
        console.log('✅ Connexion à l\'API réussie');
        
        // Vérifier s'il y a des produits
        const productsResponse = await axios.get(`${BASE_URL}/products?page=1&limit=10`);
        console.log(`📦 ${productsResponse.data.products.length} produits trouvés`);
        
        if (productsResponse.data.products.length === 0) {
            console.log('⚠️  Aucun produit trouvé. Exécutez le script insert-test-categories.sql');
        }
        
    } catch (error) {
        console.error('❌ Erreur de connexion:', error.response?.data || error.message);
    }
}

// Exécuter les tests
async function runTests() {
    console.log('🚀 Démarrage des tests de l\'API des catégories\n');
    
    await checkDatabase();
    console.log('');
    await testCategoriesAPI();
}

// Exécuter si le script est appelé directement
if (require.main === module) {
    runTests();
}

module.exports = { testCategoriesAPI, checkDatabase }; 