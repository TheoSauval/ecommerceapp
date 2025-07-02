//
//  Models.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 06/06/2025.
//

import Foundation

// MARK: - Codable Structs for API Communication

// Utilisé pour l'authentification
struct AuthTokens: Decodable {
    let accessToken: String
    let refreshToken: String?
}

// Modèle pour les réponses d'erreur du serveur
struct ErrorResponse: Codable {
    let message: String
}

// Structure pour les réponses de mise à jour du profil
struct UserProfileUpdateResponse: Codable {
    let message: String
    let user: UserProfile
}

// MARK: - User Models

struct UserProfile: Codable, Identifiable {
    let id: String
    let nom: String
    let prenom: String
    let age: Int
    let role: String
    let email: String?
    let created_at: String
    let updated_at: String

    // Mapping pour le décodage si les noms de clés JSON ne correspondent pas
    enum CodingKeys: String, CodingKey {
        case id, nom, prenom, age, role, email
        case created_at = "created_at"
        case updated_at = "updated_at"
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let email_confirmed_at: String?
    let created_at: String
    let updated_at: String
}

struct UserProfileUpdate: Codable {
    let nom: String?
    let prenom: String?
    let age: Int?
}

struct PasswordChange: Codable {
    let oldPassword: String
    let newPassword: String
}

// MARK: - Product Models

struct Product: Identifiable, Equatable, Codable, Hashable {
    let id: Int
    let nom: String
    let prix_base: Double
    let vendeur_id: Int
    let description: String?
    let categorie: String?
    let marque: String?
    let images: [String]?
    let actif: Bool
    let created_at: String
    let updated_at: String
    let product_variants: [ProductVariant]?
    
    // Computed properties for UI compatibility
    var name: String { nom }
    var prix: Double { prix_base }
    var imageName: String {
        if let images = images, !images.isEmpty, let url = images.first {
            return url
        }
        return "default_product"
    }
    var rating: Double { 5.0 } // Default value

    // Local data initializer
    init(id: Int = Int.random(in: 1...1000), name: String, category: String, imageName: String, prix: Double, rating: Double, description: String) {
        self.id = id
        self.nom = name
        self.prix_base = prix
        self.vendeur_id = 1
        self.description = description
        self.categorie = category
        self.marque = nil
        self.images = [imageName]
        self.actif = true
        self.created_at = ""
        self.updated_at = ""
        self.product_variants = nil
    }

     enum CodingKeys: String, CodingKey {
        case id, nom, prix_base, vendeur_id, description, categorie, marque, images, actif, created_at, updated_at
        case product_variants = "variants"
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ProductVariant: Codable, Equatable, Identifiable, Hashable {
    static func == (lhs: ProductVariant, rhs: ProductVariant) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let product_id: Int
    let color_id: Int
    let height_id: Int
    let stock: Int
    let prix: Double?
    let actif: Bool
    let products: Product?
    let colors: ProductColor?
    let heights: ProductSize?

    enum CodingKeys: String, CodingKey {
        case id, product_id, color_id, height_id, stock, prix, actif, products, colors, heights
    }
}

struct ProductColor: Codable, Equatable, Hashable {
    let id: Int
    let nom: String
    let code_hex: String?
}

struct ProductSize: Codable, Equatable, Hashable {
    let id: Int
    let nom: String
    let ordre: Int
}


// MARK: - Cart Models

struct CartItem: Codable, Identifiable, Equatable {
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: Int
    let user_id: String
    let variant_id: Int
    let quantity: Int
    let created_at: String
    let updated_at: String
    let product_variant: ProductVariant?
    
    // Convenience accessors - mis à jour pour correspondre à la nouvelle structure
    var variant: ProductVariant? { product_variant }
    var product: Product? { product_variant?.products }  // Changé de 'product' à 'products'
}

// MARK: - Order Models

struct Order: Codable, Identifiable {
    let id: String // Changé de Int à String pour supporter les UUIDs
    let prix_total: Double?
    let status: String?
    let user_id: String?
    let adresse_livraison: String?
    let methode_paiement: String?
    let created_at: String?
    let updated_at: String?
    let order_variants: [OrderVariant]?
}

struct OrderVariant: Codable, Identifiable {
    let order_id: String // Changé de Int à String pour supporter les UUIDs
    let variant_id: Int
    let quantity: Int
    let unit_price: Double
    let product_variant: ProductVariant?
    
    // Identifiant unique pour SwiftUI
    var id: String {
        return "\(order_id)_\(variant_id)"
    }
}

struct OrderRequest: Codable {
    let prix_total: Double
    let adresse_livraison: String
    let methode_paiement: String
    let items: [OrderItemRequest]
}

struct OrderItemRequest: Codable {
    let variant_id: Int
    let quantity: Int
    let unit_price: Double
}

// MARK: - Payment Models

struct Payment: Codable, Identifiable {
    let id: Int
    let order_id: String?
    let user_id: String?
    let amount: Double
    let status: String
    let stripe_payment_intent_id: String?
    let refund_amount: Double?
    let date_paiement: String
    let created_at: String
    let updated_at: String
}

struct PaymentRequest: Codable {
    let order_id: String
    let amount: Double
    let stripe_payment_intent_id: String?
}

// MARK: - Notification Models

struct Notification: Codable, Identifiable {
    let id: Int
    let user_id: String
    let titre: String
    let message: String
    let lu: Bool
    let type: String
    let created_at: String
    let updated_at: String
}

// MARK: - Recommendation Models

struct Recommendation: Codable, Identifiable {
    let product_id: Int
    let nom: String
    let prix_base: Double
    let description: String?
    let categorie: String?
    let marque: String?
    let images: [String]?
    let score_recommendation: Double
    
    // Computed properties pour compatibilité avec Product
    var id: Int { product_id }
    var name: String { nom }
    var prix: Double { prix_base }
    var imageName: String {
        if let images = images, !images.isEmpty, let url = images.first {
            return url
        }
        return "default_product"
    }
    var rating: Double { 5.0 }
}

struct HistoryItem: Codable, Identifiable {
    let id: Int
    let user_id: String
    let product_id: Int
    let viewed_at: String
    let view_duration: Int
    let created_at: String
    let products: Product?
}

struct ProductStats: Codable {
    let totalViews: Int
    let uniqueUsers: Int
    let totalDuration: Int
    let avgDuration: Double
    let recentViews: Int
}

struct CategoryPreference: Codable {
    let categorie: String
    let totalViews: Int
    let totalDuration: Int
    let avgDuration: Double
    let categoryScore: Double
    
    enum CodingKeys: String, CodingKey {
        case categorie
        case totalViews = "total_views"
        case totalDuration = "total_duration"
        case avgDuration = "avg_duration"
        case categoryScore = "category_score"
    }
}

struct UserAnalytics: Codable {
    let totalViews: Int
    let totalDuration: Int
    let favoriteCategory: String?
    let favoriteProductId: Int?
    let avgSessionDuration: Double
    
    enum CodingKeys: String, CodingKey {
        case totalViews = "total_views"
        case totalDuration = "total_duration"
        case favoriteCategory = "favorite_category"
        case favoriteProductId = "favorite_product_id"
        case avgSessionDuration = "avg_session_duration"
    }
}

struct PopularProduct: Codable, Identifiable {
    let id: Int
    let nom: String
    let prix_base: Double
    let description: String?
    let categorie: String?
    let marque: String?
    let images: [String]?
    let viewCount: Int
    
    // Computed properties pour compatibilité avec Product
    var name: String { nom }
    var prix: Double { prix_base }
    var imageName: String {
        if let images = images, !images.isEmpty, let url = images.first {
            return url
        }
        return "default_product"
    }
    var rating: Double { 5.0 }
}

// MARK: - Category Filter

enum CategoryFilter: String, CaseIterable, Hashable {
    case all = "Tous les items"
    case manteau = "Manteau"
    case tshirt = "T-Shirt"
    case sweat = "Sweat"
}

// MARK: - Local Test Data

let allProducts: [Product] = [
    Product(
        name: "Doudoune",
        category: CategoryFilter.manteau.rawValue,
        imageName: "Doudoune",
        prix: 162.99,
        rating: 5.0,
        description: "Doudoune épaisse parfaite pour l'hiver, coupe moderne et tissu déperlant."
    ),
    Product(
        name: "Sweat noir",
        category: CategoryFilter.sweat.rawValue,
        imageName: "image_enfant",
        prix: 59.99,
        rating: 5.0,
        description: "Sweat confortable en coton bio, idéal pour un look streetwear."
    ),
    Product(
        name: "Sweat gris",
        category: CategoryFilter.sweat.rawValue,
        imageName: "Sweat_gris",
        prix: 59.99,
        rating: 5.0,
        description: "Sweat gris unisexe, coupe oversize, molleton intérieur doux."
    ),
    Product(
        name: "Parka noir",
        category: CategoryFilter.manteau.rawValue,
        imageName: "Parka",
        prix: 159.99,
        rating: 5.0,
        description: "Parka imperméable avec capuche amovible et doublure chaude."
    ),
    Product(
        name: "T-Shirt blanc",
        category: CategoryFilter.tshirt.rawValue,
        imageName: "T-shirt_blanc",
        prix: 29.99,
        rating: 5.0,
        description: "T-shirt basique blanc en coton 100%, coupe droite et col rond."
    )
]

// MARK: - Modèles pour la création de commande backend (compatibilité Node.js)
struct OrderItemBackend: Codable {
    let productId: Int
    let variantId: Int
    let quantity: Int
}

struct OrderRequestBackend: Codable {
    let items: [OrderItemBackend]
    let adresse_livraison: String
    let methode_paiement: String
}

// MARK: - Error Response Model

struct ServerErrorResponse: Codable {
    let message: String
} 