//
//  CartManager.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/05/2025.
//

import Foundation
import SwiftUI


class CartManager: ObservableObject {
    @Published var items: [Product] = []
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.prix }
    }
    
    func add(_ product: Product) {
        if !items.contains(where: { $0.id == product.id }) {
            items.append(product)
        }
    }
    
    func remove(_ product: Product) {
        items.removeAll { $0.id == product.id }
    }
    
    
    func clear() {
        items.removeAll()
    }
}
