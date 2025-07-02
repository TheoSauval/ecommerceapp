# Filtres de Catégories Dynamiques - Application Mobile Swift

## Vue d'ensemble

Cette implémentation permet d'afficher des filtres de catégories dynamiques dans votre application mobile Swift, basés uniquement sur les catégories qui existent réellement dans votre base de données et qui ont des produits actifs avec du stock disponible.

## Fonctionnalités

- ✅ **Filtres dynamiques** : Seules les catégories avec des produits en stock sont affichées
- ✅ **Filtres spéciaux** : "Tous" et "Recommandations" toujours disponibles
- ✅ **Pagination** : Chargement progressif des produits
- ✅ **Interface moderne** : Design SwiftUI avec animations fluides
- ✅ **Gestion d'erreurs** : Gestion robuste des cas d'erreur

## API Endpoints

### 1. Récupérer les catégories disponibles
```
GET /api/products/categories
```

**Réponse :**
```json
[
  "Manteau",
  "T-Shirt", 
  "Sweat",
  "Pantalon",
  "Chaussure"
]
```

### 2. Filtrer les produits par catégorie
```
GET /api/products/category/:category?page=1&limit=10
```

**Réponse :**
```json
{
  "products": [...],
  "totalPages": 5,
  "currentPage": 1,
  "category": "Manteau"
}
```

## Structure du Code Swift

### Modèles de données
- `Category` : Représente une catégorie de produit
- `Product` : Modèle de produit avec ses variantes
- `ProductVariant` : Variantes de produit (taille, couleur, stock)
- `ProductsResponse` : Réponse paginée de l'API

### Service API
- `ProductService` : Gère toutes les interactions avec l'API
- Chargement automatique des catégories au démarrage
- Gestion de la pagination
- Cache des données

### Interface utilisateur
- `ProductListView` : Vue principale avec filtres
- `CategoryFilterButton` : Bouton de filtre individuel
- `ProductCard` : Carte de produit

## Installation et Configuration

### 1. Backend (Node.js/Express)

Assurez-vous que les endpoints suivants sont disponibles :

```javascript
// routes/products.js
router.get('/categories', productController.getAvailableCategories);
router.get('/category/:category', productController.getProductsByCategory);
```

### 2. Base de données

Exécutez le script de diagnostic pour vérifier vos catégories :

```sql
-- Voir les catégories existantes
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

### 3. Données de test

Si vous n'avez pas de données, exécutez le script `insert-test-categories.sql` pour créer des produits de test avec des catégories appropriées.

## Utilisation dans votre App Swift

### 1. Intégrer le service

```swift
@StateObject private var productService = ProductService()
```

### 2. Afficher les filtres

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(productService.categories) { category in
            CategoryFilterButton(
                category: category,
                isSelected: selectedCategory?.name == category.name
            ) {
                selectedCategory = category
                productService.loadProducts(category: category)
            }
        }
    }
}
```

### 3. Afficher les produits

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(productService.products) { product in
            ProductCard(product: product)
                .onAppear {
                    // Charger plus de produits automatiquement
                    if product.id == productService.products.last?.id {
                        productService.loadMoreProducts()
                    }
                }
        }
    }
}
```

## Personnalisation

### Modifier les filtres spéciaux

Dans `ProductService.loadCategories()` :

```swift
var allCategories: [Category] = [
    Category(name: "Tous"),
    Category(name: "Recommandations"),
    Category(name: "Nouveautés"), // Ajouter d'autres filtres
    Category(name: "Promotions")
]
```

### Modifier le style des boutons

Dans `CategoryFilterButton` :

```swift
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(isSelected ? Color.blue : Color(.systemGray5))
)
```

### Ajouter des animations

```swift
.animation(.easeInOut(duration: 0.3), value: selectedCategory)
```

## Dépannage

### Problème : Catégorie "Manteau" apparaît mais pas de produits

**Solution :**
1. Vérifiez que vous avez des produits avec la catégorie "Manteau" en base
2. Vérifiez que ces produits ont des variantes avec du stock > 0
3. Exécutez le script de diagnostic `debug-categories.sql`

### Problème : Filtres ne se chargent pas

**Solution :**
1. Vérifiez que l'endpoint `/api/products/categories` fonctionne
2. Vérifiez la configuration de l'URL de base dans `ProductService`
3. Vérifiez les logs de l'API

### Problème : Pagination ne fonctionne pas

**Solution :**
1. Vérifiez que l'endpoint retourne `totalPages` et `currentPage`
2. Vérifiez que `loadMoreProducts()` est appelé correctement
3. Vérifiez les logs de l'API

## Performance

- Les catégories sont chargées une seule fois au démarrage
- La pagination évite de charger tous les produits d'un coup
- Les images sont chargées de manière asynchrone
- Le cache local améliore les performances

## Sécurité

- Validation des données côté serveur
- Gestion des erreurs robuste
- Pas d'injection SQL possible avec les requêtes préparées
- Authentification requise pour les opérations sensibles 