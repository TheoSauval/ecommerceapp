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
    
    func addToFavorites(_ product: Product) {
        if !favorites.contains(where: { $0.id == product.id }) {
            favorites.append(product)
        }
    }
    
    func removeFromFavorites(_ product: Product) {
        favorites.removeAll() { $0.id == product.id }
    }
    
    func isFavorite(_ product: Product) -> Bool {
        favorites.contains(where: { $0.id == product.id })
    }
}
