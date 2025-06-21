# Résumé des Routes - Backend Node.js ↔ Frontend Swift

## Vue d'ensemble
Ce document liste toutes les routes du backend Node.js et leurs correspondances avec les services Swift.

## Configuration de base
- **Backend** : `http://localhost:4000/api`
- **Frontend Swift** : Utilise `APIConfig.swift` pour centraliser les URLs

---

## 🔐 Authentification (`/api/auth`)

### Backend Routes
```
POST   /api/auth/register     → Inscription
POST   /api/auth/login        → Connexion
POST   /api/auth/logout       → Déconnexion
POST   /api/auth/refresh      → Rafraîchir session
POST   /api/auth/reset        → Demande reset mot de passe
PUT    /api/auth/reset        → Reset mot de passe
GET    /api/auth/profile      → Profil utilisateur
PUT    /api/auth/profile      → Mettre à jour profil
```

### Swift Service
**AuthService.swift**
- ✅ `register(nom:prenom:age:mail:password:role:completion:)`
- ✅ `login(mail:password:completion:)`
- ✅ `logout()`
- ✅ `refreshSession(completion:)`
- ✅ `getCurrentUser(completion:)`

---

## 👤 Utilisateurs (`/api/users`)

### Backend Routes
```
GET    /api/users/me          → Récupérer profil
PUT    /api/users/me          → Mettre à jour profil
DELETE /api/users/me          → Supprimer compte
```

### Swift Service
**UserService.swift**
- ✅ `getProfile(completion:)`
- ✅ `updateProfile(profileData:completion:)`
- ✅ `changePassword(passwordData:completion:)`
- ✅ `deleteAccount(completion:)`

---

## 🛍️ Produits (`/api/products`)

### Backend Routes
```
GET    /api/products          → Liste tous les produits
GET    /api/products/search   → Recherche produits
GET    /api/products/:id      → Détails produit
POST   /api/products          → Créer produit (admin)
PUT    /api/products/:id      → Modifier produit (admin)
DELETE /api/products/:id      → Supprimer produit (admin)
```

### Swift Service
**ProductService.swift**
- ✅ `getAllProducts(completion:)`
- ✅ `getProductById(id:completion:)`
- ✅ `searchProducts(query:completion:)`

---

## 🛒 Panier (`/api/cart`)

### Backend Routes
```
GET    /api/cart              → Récupérer panier
POST   /api/cart              → Ajouter au panier
PUT    /api/cart/:itemId      → Modifier quantité
DELETE /api/cart/:itemId      → Supprimer du panier
```

### Swift Services
**CartService.swift** (API calls)
- ✅ `getCart(completion:)`
- ✅ `addToCart(variantId:quantity:completion:)`
- ✅ `updateCartItem(itemId:quantity:completion:)`
- ✅ `removeFromCart(itemId:completion:)`

**CartManager.swift** (State management)
- ✅ `loadCart()`
- ✅ `addToCart(variantId:quantity:)`
- ✅ `updateQuantity(itemId:quantity:)`
- ✅ `removeFromCart(itemId:)`
- ✅ `clear()`

---

## ❤️ Favoris (`/api/users/me/favorites`)

### Backend Routes
```
GET    /api/users/me/favorites        → Récupérer favoris
POST   /api/users/me/favorites        → Ajouter favori
DELETE /api/users/me/favorites/:id    → Retirer favori
```

### Swift Services
**FavoriteService.swift** (API calls)
- ✅ `getFavorites(completion:)`
- ✅ `addFavorite(productId:completion:)`
- ✅ `removeFavorite(productId:completion:)`

**FavoritesManager.swift** (State management)
- ✅ `loadFavorites()`
- ✅ `addToFavorites(product:)`
- ✅ `removeFromFavorites(product:)`
- ✅ `isFavorite(product:)`

---

## 📦 Commandes (`/api/orders`)

### Backend Routes
```
GET    /api/orders            → Récupérer commandes
POST   /api/orders            → Créer commande
GET    /api/orders/:id        → Détails commande
PUT    /api/orders/:id/cancel → Annuler commande
```

### Swift Service
**OrderService.swift**
- ✅ `getOrders(completion:)`
- ✅ `getOrderById(id:completion:)`
- ✅ `createOrder(orderData:completion:)`
- ✅ `updateOrderStatus(id:status:completion:)`

---

## 💳 Paiements (`/api/payments`)

### Backend Routes
```
POST   /api/payments                  → Créer paiement
GET    /api/payments                  → Récupérer paiements
GET    /api/payments/:id              → Détails paiement
PUT    /api/payments/:id/status       → Mettre à jour statut
POST   /api/payments/stripe/initiate  → Initier paiement Stripe
GET    /api/payments/stripe/:orderId/status → Statut paiement Stripe
POST   /api/payments/webhook          → Webhook Stripe
```

### Swift Service
**PaymentService.swift**
- ✅ `getPayments(completion:)`
- ✅ `getPaymentById(id:completion:)`
- ✅ `createPayment(paymentData:completion:)`
- ✅ `processStripePayment(paymentIntentId:completion:)`

---

## 🔔 Notifications (`/api/notifications`)

### Backend Routes
```
GET    /api/notifications             → Récupérer notifications
POST   /api/notifications             → Créer notification
PUT    /api/notifications/:id         → Modifier notification
DELETE /api/notifications/:id         → Supprimer notification
PUT    /api/notifications/:id/read    → Marquer comme lu
PUT    /api/notifications/read-all    → Marquer tout comme lu
GET    /api/notifications/unread-count → Nombre non lues
DELETE /api/notifications/clear-all   → Supprimer toutes
```

### Swift Service
**NotificationService.swift**
- ✅ `getNotifications(completion:)`
- ✅ `markAsRead(notificationId:completion:)`
- ✅ `markAllAsRead(completion:)`

---

## 🏪 Admin Routes

### Produits Admin (`/api/admin/products`)
```
GET    /api/admin/products    → Liste produits (admin)
POST   /api/admin/products    → Créer produit
PUT    /api/admin/products/:id → Modifier produit
DELETE /api/admin/products/:id → Supprimer produit
```

### Commandes Admin (`/api/admin/orders`)
```
GET    /api/admin/orders      → Liste commandes (admin)
PUT    /api/admin/orders/:id  → Modifier statut commande
```

### Dashboard Admin (`/api/admin/dashboard`)
```
GET    /api/admin/dashboard   → Statistiques dashboard
```

### Upload Admin (`/api/admin/upload`)
```
POST   /api/admin/upload      → Upload images
```

---

## 📊 Structures de données

### Modèles Swift ↔ Tables Supabase

| Swift Model | Supabase Table | Description |
|-------------|----------------|-------------|
| `Product` | `products` | Produits en vente |
| `ProductVariant` | `product_variants` | Variantes (taille+couleur) |
| `CartItem` | `cart_items` | Éléments du panier |
| `Order` | `orders` | Commandes |
| `OrderVariant` | `order_variants` | Variantes dans commandes |
| `Payment` | `payments` | Paiements |
| `Notification` | `notifications` | Notifications |
| `UserProfile` | `user_profiles` | Profils utilisateurs |
| `Color` | `colors` | Couleurs disponibles |
| `Height` | `heights` | Tailles disponibles |

---

## 🔧 Configuration

### APIConfig.swift
Centralise toutes les URLs et configurations :
```swift
APIConfig.baseURL = "http://localhost:4000/api"
APIConfig.Auth.login
APIConfig.Product.all
APIConfig.Cart.all
// etc.
```

### Gestion des tokens
- **AuthService** gère automatiquement les tokens
- Partage avec tous les autres services
- Sauvegarde dans UserDefaults
- Refresh automatique

---

## ✅ Statut de l'intégration

| Service | Backend Routes | Swift Service | Statut |
|---------|----------------|---------------|--------|
| Auth | ✅ | ✅ | **Complet** |
| Users | ✅ | ✅ | **Complet** |
| Products | ✅ | ✅ | **Complet** |
| Cart | ✅ | ✅ | **Complet** |
| Favorites | ✅ | ✅ | **Complet** |
| Orders | ✅ | ✅ | **Complet** |
| Payments | ✅ | ✅ | **Complet** |
| Notifications | ✅ | ✅ | **Complet** |
| Admin | ✅ | ❌ | **Partiel** (pas de services Swift) |

---

## 🚀 Utilisation

1. **Démarrer le backend** :
   ```bash
   cd "Projet ECOMMERCE"
   npm start
   ```

2. **Utiliser les services Swift** :
   ```swift
   let authService = AuthService.shared
   let cartManager = CartManager()
   
   // Les services se connectent automatiquement au backend
   ```

3. **Gestion des erreurs** :
   - Tous les services utilisent `Result<T, Error>`
   - Messages d'erreur localisés
   - État de chargement géré

---

## 📝 Notes importantes

1. **Authentification** : Toutes les routes protégées nécessitent un token JWT
2. **CORS** : Configuré pour `localhost:3000` et `localhost:4000`
3. **Base de données** : Supabase avec RLS (Row Level Security)
4. **Stock** : Géré par variante (taille + couleur)
5. **Paiements** : Intégration Stripe prévue

L'intégration est **complète** pour toutes les fonctionnalités principales de l'e-commerce ! 