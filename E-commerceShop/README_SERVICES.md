# Services Swift - Documentation

Ce document explique comment utiliser les services Swift pour communiquer avec le backend Node.js.

## Architecture

L'application Swift utilise une architecture de services pour communiquer avec l'API backend :

- **AuthService** : Gestion de l'authentification et des tokens
- **ProductService** : Gestion des produits
- **CartService** : Gestion du panier
- **FavoriteService** : Gestion des favoris
- **OrderService** : Gestion des commandes
- **PaymentService** : Gestion des paiements
- **NotificationService** : Gestion des notifications
- **UserService** : Gestion du profil utilisateur

## Configuration

### APIConfig.swift
Centralise toutes les URLs et configurations de l'API :

```swift
// URL de base
APIConfig.baseURL = "http://localhost:4000/api"

// Endpoints spécifiques
APIConfig.Auth.login
APIConfig.Product.all
APIConfig.Cart.all
```

## Authentification

### AuthService
Gère l'authentification et partage automatiquement les tokens avec tous les autres services.

```swift
let authService = AuthService.shared

// Inscription
authService.register(
    nom: "Dupont",
    prenom: "Jean",
    age: 25,
    mail: "jean@example.com",
    password: "password123"
) { result in
    switch result {
    case .success(let response):
        print("Inscription réussie")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Connexion
authService.login(
    mail: "jean@example.com",
    password: "password123"
) { result in
    switch result {
    case .success(let response):
        print("Connexion réussie")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Déconnexion
authService.logout()
```

## Produits

### ProductService
Gère la récupération des produits depuis l'API.

```swift
let productService = ProductService.shared

// Récupérer tous les produits
productService.getAllProducts { result in
    switch result {
    case .success(let products):
        print("Produits récupérés: \(products.count)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Récupérer un produit par ID
productService.getProductById(id: 1) { result in
    switch result {
    case .success(let product):
        print("Produit: \(product.nom)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Rechercher des produits
productService.searchProducts(query: "t-shirt") { result in
    switch result {
    case .success(let products):
        print("Résultats: \(products.count)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}
```

## Panier

### CartService & CartManager
Le CartService gère les appels API, le CartManager gère l'état local.

```swift
let cartManager = CartManager()

// Charger le panier depuis l'API
cartManager.loadCart()

// Ajouter un produit au panier
cartManager.addToCart(variantId: 1, quantity: 2)

// Mettre à jour la quantité
cartManager.updateQuantity(itemId: 1, quantity: 3)

// Supprimer du panier
cartManager.removeFromCart(itemId: 1)

// Vider le panier
cartManager.clear()
```

## Favoris

### FavoriteService & FavoritesManager
Gestion des produits favoris.

```swift
let favoritesManager = FavoritesManager()

// Charger les favoris
favoritesManager.loadFavorites()

// Ajouter aux favoris
favoritesManager.addToFavorites(product)

// Retirer des favoris
favoritesManager.removeFromFavorites(product)

// Vérifier si favori
let isFavorite = favoritesManager.isFavorite(product)
```

## Commandes

### OrderService
Gestion des commandes.

```swift
let orderService = OrderService.shared

// Récupérer les commandes
orderService.getOrders { result in
    switch result {
    case .success(let orders):
        print("Commandes: \(orders.count)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Créer une commande
let orderRequest = OrderRequest(
    prix_total: 99.99,
    adresse_livraison: "123 Rue de la Paix",
    methode_paiement: "carte",
    items: [
        OrderItemRequest(variant_id: 1, quantity: 2, unit_price: 49.99)
    ]
)

orderService.createOrder(orderData: orderRequest) { result in
    switch result {
    case .success(let order):
        print("Commande créée: \(order.id)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}
```

## Paiements

### PaymentService
Gestion des paiements.

```swift
let paymentService = PaymentService.shared

// Récupérer les paiements
paymentService.getPayments { result in
    switch result {
    case .success(let payments):
        print("Paiements: \(payments.count)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Traiter un paiement Stripe
paymentService.processStripePayment(paymentIntentId: "pi_123") { result in
    switch result {
    case .success(let payment):
        print("Paiement traité: \(payment.id)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}
```

## Notifications

### NotificationService
Gestion des notifications.

```swift
let notificationService = NotificationService.shared

// Récupérer les notifications
notificationService.getNotifications { result in
    switch result {
    case .success(let notifications):
        print("Notifications: \(notifications.count)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Marquer comme lu
notificationService.markAsRead(notificationId: 1) { result in
    switch result {
    case .success(let notification):
        print("Notification marquée comme lue")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}
```

## Utilisateurs

### UserService
Gestion du profil utilisateur.

```swift
let userService = UserService.shared

// Récupérer le profil
userService.getProfile { result in
    switch result {
    case .success(let profile):
        print("Profil: \(profile.nom) \(profile.prenom)")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}

// Mettre à jour le profil
let updateData = UserProfileUpdate(
    nom: "Nouveau Nom",
    prenom: "Nouveau Prénom",
    age: 30
)

userService.updateProfile(profileData: updateData) { result in
    switch result {
    case .success(let profile):
        print("Profil mis à jour")
    case .failure(let error):
        print("Erreur: \(error)")
    }
}
```

## Gestion des erreurs

Tous les services utilisent le type `Result<T, Error>` pour gérer les erreurs de manière uniforme.

```swift
// Exemple de gestion d'erreur
service.someMethod { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let data):
            // Traitement des données
            self.updateUI(with: data)
        case .failure(let error):
            // Gestion de l'erreur
            self.showError(error.localizedDescription)
        }
    }
}
```

## État de chargement

Les managers (CartManager, FavoritesManager) incluent des propriétés pour gérer l'état de chargement :

```swift
@Published var isLoading = false
@Published var errorMessage: String?

// Dans la vue SwiftUI
if cartManager.isLoading {
    ProgressView()
} else if let error = cartManager.errorMessage {
    Text("Erreur: \(error)")
} else {
    // Contenu normal
}
```

## Intégration avec SwiftUI

Pour utiliser ces services dans SwiftUI, injectez-les dans l'environnement ou utilisez-les directement dans les vues :

```swift
struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartManager = CartManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some View {
        if authService.isAuthenticated {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(cartManager)
                .environmentObject(favoritesManager)
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}
```

## Correspondance avec le backend

Les services Swift correspondent exactement aux routes du backend Node.js :

| Service Swift | Routes Backend |
|---------------|----------------|
| AuthService | `/api/auth/*` |
| ProductService | `/api/products/*` |
| CartService | `/api/cart/*` |
| FavoriteService | `/api/users/me/favorites/*` |
| OrderService | `/api/orders/*` |
| PaymentService | `/api/payments/*` |
| NotificationService | `/api/notifications/*` |
| UserService | `/api/users/me/*` |

## Notes importantes

1. **Tokens d'authentification** : L'AuthService gère automatiquement les tokens et les partage avec tous les autres services.

2. **Threading** : Tous les callbacks sont exécutés sur le thread principal pour la mise à jour de l'UI.

3. **Gestion d'erreur** : Chaque service inclut une gestion d'erreur appropriée avec des messages localisés.

4. **État local** : Les managers maintiennent un état local synchronisé avec le backend.

5. **Configuration** : Utilisez APIConfig pour centraliser les URLs et configurations. 