//
//  FavoritesManager.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 04/04/2025.
//

import Foundation
import SwiftUI

class FavoritesManager: ObservableObject {
    @Published var favorites: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let favoriteService = FavoriteService.shared
    
    func loadFavorites() {
        isLoading = true
        errorMessage = nil
        
        favoriteService.getFavorites { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let products):
                    self?.favorites = products
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addToFavorites(_ product: Product) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.addFavorite(productId: product.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.loadFavorites()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func removeFromFavorites(_ product: Product) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.removeFavorite(productId: product.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.loadFavorites()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func isFavorite(_ product: Product) -> Bool {
        favorites.contains(where: { $0.id == product.id })
    }
}
