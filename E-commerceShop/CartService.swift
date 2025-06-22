//
//  CartService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class CartService {
    static let shared = CartService() // Instance partagée (Singleton)
    private let api = APIConfig.shared
    
    private init() {} // Empêche la création d'autres instances

    // Récupère l'intégralité du panier de l'utilisateur
    func fetchCart(completion: @escaping (Result<[CartItem], Error>) -> Void) {
        api.request(endpoint: "/api/cart", method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let cartItems = try JSONDecoder().decode([CartItem].self, from: data)
                    completion(.success(cartItems))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Ajoute un produit au panier
    func addToCart(variantId: Int, quantity: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let body: [String: Any] = ["variantId": variantId, "quantity": quantity]
        
        api.request(endpoint: "/api/cart", method: "POST", body: body) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Met à jour la quantité d'un article dans le panier
    func updateCartItem(cartItemId: Int, quantity: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let body: [String: Any] = ["quantity": quantity]
        
        api.request(endpoint: "/api/cart/\(cartItemId)", method: "PUT", body: body) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // Supprime un article du panier
    func removeFromCart(cartItemId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(endpoint: "/api/cart/\(cartItemId)", method: "DELETE") { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Vide complètement le panier
    func clearCart(completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(endpoint: "/api/cart/clear", method: "DELETE") { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}