import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartManager = CartManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var productViewModel = ProductViewModel()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authService)
        .environmentObject(cartManager)
        .environmentObject(favoritesManager)
        .environmentObject(productViewModel)
    }
}

struct MainTabView: View {
    @EnvironmentObject var cartManager: CartManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favoris", systemImage: "heart")
                }

            CartView()
                .tabItem {
                    Label("Panier", systemImage: "cart")
                }
                .badge(cartManager.cartItems.count)

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
