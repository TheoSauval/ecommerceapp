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

// MARK: - User Models

struct UserProfile: Codable, Identifiable {
    let id: String
    let nom: String
    let prenom: String
    let age: Int
    let role: String
    let created_at: String
    let updated_at: String
    let auth_users: AuthUser?

    // Computed property to easily access email
    var mail: String {
        auth_users?.email ?? "N/A"
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
    let current_password: String
    let new_password: String
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
        case id, nom, prix_base, vendeur_id, description, categorie, marque, images, actif, created_at, updated_at, product_variants
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
    let product: Product?
    let color: ProductColor?
    let height: ProductSize?
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
    
    // Convenience accessors
    var variant: ProductVariant? { product_variant }
    var product: Product? { product_variant?.product }
}

// MARK: - Order Models

struct Order: Codable, Identifiable {
    let id: Int
    let prix_total: Double
    let status: String
    let user_id: String?
    let adresse_livraison: String?
    let methode_paiement: String?
    let created_at: String
    let updated_at: String
    let order_variants: [OrderVariant]?
}

struct OrderVariant: Codable {
    let order_id: Int
    let variant_id: Int
    let quantity: Int
    let unit_price: Double
    let product_variant: ProductVariant?
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
    let order_id: Int?
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
    let order_id: Int
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