# 🚀 Guide de Démarrage - Filtres de Catégories Dynamiques

## 📋 Étapes pour tester les filtres dynamiques

### 1. Vérifier la base de données

Exécutez d'abord le script de diagnostic pour voir vos catégories actuelles :

```sql
-- Dans votre base de données Supabase
SELECT 
    categorie,
    COUNT(*) as nombre_produits
FROM public.products 
WHERE actif = true 
    AND categorie IS NOT NULL 
    AND categorie != ''
GROUP BY categorie
ORDER BY nombre_produits DESC;
```

### 2. Ajouter des données de test (si nécessaire)

Si vous n'avez pas de produits avec des catégories, exécutez :

```sql
-- Exécuter le script insert-test-categories.sql dans Supabase
```

### 3. Démarrer le serveur backend

```bash
cd "Projet ECOMMERCE"
npm start
```

### 4. Tester l'API

```bash
# Installer axios si nécessaire
npm install axios

# Tester l'API
node test-api-categories.js
```

Vous devriez voir quelque chose comme :
```
🚀 Démarrage des tests de l'API des catégories

🔍 Vérification de la base de données...

✅ Connexion à l'API réussie
📦 15 produits trouvés

🧪 Test de l'API des catégories...

1️⃣ Test GET /api/products/categories
✅ Succès!
📋 Catégories récupérées: ['Chaussure', 'Manteau', 'Pantalon', 'Sweat', 'T-Shirt']
📊 Nombre de catégories: 5
```

### 5. Tester dans l'application mobile

1. **Ouvrez votre projet Swift**
2. **Assurez-vous que l'URL de base est correcte** dans `CategoryService.swift` :
   ```swift
   private let baseURL = "http://localhost:3000/api"
   ```
3. **Lancez l'application**
4. **Allez dans la page "Boutique"**
5. **Vérifiez que les filtres se chargent dynamiquement**

## 🔧 Dépannage

### Problème : "Aucune catégorie trouvée"

**Solution :**
1. Vérifiez que vous avez des produits avec des catégories en base
2. Vérifiez que ces produits ont des variantes avec du stock > 0
3. Exécutez le script `insert-test-categories.sql`

### Problème : "Erreur de connexion à l'API"

**Solution :**
1. Vérifiez que le serveur backend est démarré
2. Vérifiez l'URL dans `CategoryService.swift`
3. Vérifiez les logs du serveur

### Problème : "Filtres ne se chargent pas dans l'app"

**Solution :**
1. Vérifiez les logs de l'application Swift
2. Vérifiez que `CategoryService` est bien initialisé
3. Vérifiez la console pour les erreurs de décodage

## 📱 Résultat attendu

Dans votre application mobile, vous devriez voir :

1. **Filtres dynamiques** qui s'adaptent aux catégories en base
2. **Filtres spéciaux** : "Tous" et "Recommandations" toujours présents
3. **Chargement automatique** des catégories au démarrage
4. **Gestion d'erreurs** avec fallback vers des catégories par défaut

## 🎯 Exemple de filtres attendus

Si vous avez des produits avec ces catégories en base :
- Manteau
- T-Shirt  
- Sweat
- Pantalon
- Chaussure

Vos filtres devraient afficher :
```
[Tous] [Recommandations] [Manteau] [T-Shirt] [Sweat] [Pantalon] [Chaussure]
```

## 🔄 Mise à jour des catégories

Les catégories se mettent à jour automatiquement quand :
- Vous ajoutez de nouveaux produits avec de nouvelles catégories
- Vous supprimez tous les produits d'une catégorie
- Vous modifiez les catégories des produits existants

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifiez les logs** du serveur backend
2. **Vérifiez les logs** de l'application Swift
3. **Testez l'API** avec le script `test-api-categories.js`
4. **Vérifiez la base de données** avec le script `debug-categories.sql` 