import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var favoriteProducts: [Product] = []
    @StateObject var cartManager = CartManager()
    @State private var isLoggedIn = false  // 🆕 Gestion de la session

    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    HomeView(favoriteProducts: $favoriteProducts, selectedTab: $selectedTab)
                        .tag(0)

                    FavoritesView(favorites: $favoriteProducts, selectedTab: $selectedTab)
                        .tag(1)

                    CartView()
                        .tag(2)

                    // 👇 Affiche LoginView ou ProfileView selon connexion
                    Group {
                        if isLoggedIn {
                            ProfileView {
                                isLoggedIn = false  // 👈 Déconnexion
                            }
                            .tag(3)
                        } else {
                            LoginView(isLoggedIn: $isLoggedIn)
                                .tag(3)
                        }
                    }
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        TabButton(systemIcon: "house.fill", index: 0, selectedTab: $selectedTab)
                        TabButton(systemIcon: "heart.fill", index: 1, selectedTab: $selectedTab)
                        TabButton(systemIcon: "basket.fill", index: 2, selectedTab: $selectedTab)
                        TabButton(systemIcon: "person.fill", index: 3, selectedTab: $selectedTab)
                    }
                    .padding()
                    .background(Color.black)
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(Color.white)
        }
        .environmentObject(cartManager)
    }
}
