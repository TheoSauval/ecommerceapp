import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartManager = CartManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var productViewModel = ProductViewModel()
    @StateObject private var viewRouter = ViewRouter()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                NavigationView {
                    LoginView()
                }
            }
        }
        .environmentObject(authService)
        .environmentObject(cartManager)
        .environmentObject(favoritesManager)
        .environmentObject(productViewModel)
        .environmentObject(viewRouter)
    }
}

struct MainTabView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        TabView(selection: $viewRouter.currentTab) {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(Tab.home)
            
            FavoritesView()
                .tabItem {
                    Label("Favoris", systemImage: "heart")
                }
                .tag(Tab.favorites)

            CartView()
                .tabItem {
                    Label("Panier", systemImage: "cart")
                }
                .badge(cartManager.cartItems.count)
                .tag(Tab.cart)

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
                .tag(Tab.profile)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
