//
//  E_commerceShopApp.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 31/03/2025.
//

import SwiftUI

@main
struct E_commerceShopApp: App {
    // Initialise tous les services et managers ici
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartManager = CartManager()
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Injecte les objets dans l'environnement SwiftUI
                .environmentObject(authService)
                .environmentObject(cartManager)
                .environmentObject(favoritesManager)
        }
    }
}
