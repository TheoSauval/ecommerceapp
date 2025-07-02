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
    @StateObject private var recommendationViewModel = RecommendationViewModel()
    @StateObject private var urlSchemeHandler = URLSchemeHandler.shared
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Injecte les objets dans l'environnement SwiftUI
                .environmentObject(authService)
                .environmentObject(cartManager)
                .environmentObject(favoritesManager)
                .environmentObject(recommendationViewModel)
                .environmentObject(urlSchemeHandler)
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .onOpenURL { url in
                    // Gérer les URL schemes (retour de Stripe)
                    urlSchemeHandler.handleURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // L'app revient au premier plan
                    print("🔄 Application revient au premier plan")
                    // Réinitialiser l'état du URLSchemeHandler
                    urlSchemeHandler.resetPaymentResult()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // L'app passe en arrière-plan
                    print("📱 Application passe en arrière-plan")
                    // Nettoyer les états de paiement si nécessaire
                    // Note: On ne nettoie pas automatiquement pour permettre le retour de Stripe
                }
        }
    }
}
