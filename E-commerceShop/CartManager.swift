//
//  CartManager.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/05/2025.
//

import Foundation
import SwiftUI


class CartManager: ObservableObject {
    @Published var cartItems: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cartService = CartService.shared
    
    var totalPrice: Double {
        cartItems.reduce(0) { total, item in
            guard let variant = item.variant, let product = variant.product else { return total }
            let price = variant.prix ?? product.prix_base
            return total + (price * Double(item.quantity))
        }
    }
    
    func fetchCart() {
        isLoading = true
        errorMessage = nil
        
        cartService.fetchCart { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let items):
                    self?.cartItems = items
                case .failure(let error):
                    self?.errorMessage = "Erreur de chargement du panier: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func addToCart(variantId: Int, quantity: Int = 1) {
        isLoading = true
        errorMessage = nil
        
        cartService.addToCart(variantId: variantId, quantity: quantity) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.fetchCart() // Re-fetch to get updated cart state
                case .failure(let error):
                    self?.errorMessage = "Erreur d'ajout au panier: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateQuantity(cartItemId: Int, newQuantity: Int) {
        guard newQuantity > 0 else {
            removeFromCart(cartItemId: cartItemId)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        cartService.updateCartItem(cartItemId: cartItemId, quantity: newQuantity) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.fetchCart()
                case .failure(let error):
                    self?.errorMessage = "Erreur de mise à jour: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func removeFromCart(cartItemId: Int) {
        isLoading = true
        errorMessage = nil
        
        cartService.removeFromCart(cartItemId: cartItemId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.fetchCart()
                case .failure(let error):
                    self?.errorMessage = "Erreur de suppression: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func increaseQuantity(for item: CartItem) {
        updateQuantity(cartItemId: item.id, newQuantity: item.quantity + 1)
    }
    
    func decreaseQuantity(for item: CartItem) {
        updateQuantity(cartItemId: item.id, newQuantity: item.quantity - 1)
    }
    
    func clearCart() {
        isLoading = true
        errorMessage = nil
        
        cartService.clearCart { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.cartItems = []
                case .failure(let error):
                    self?.errorMessage = "Erreur pour vider le panier: \(error.localizedDescription)"
                }
            }
        }
    }
}

