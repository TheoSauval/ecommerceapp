import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager

    var body: some View {
        NavigationView {
            VStack {
                if favoritesManager.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if favoritesManager.favorites.isEmpty {
                    Spacer()
                    Text("Vous n'avez pas encore de favoris.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                            ForEach(favoritesManager.favorites) { product in
                                ProductCardView(product: product)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favoris")
            .onAppear {
                // Si l'utilisateur est authentifié, chargez les favoris depuis le backend.
                // Note : La logique d'authentification doit être ajoutée ici.
                // Pour l'instant, cela suppose que le token est déjà défini.
                favoritesManager.loadFavorites()
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        // Crée une instance de manager pour la prévisualisation
        let manager = FavoritesManager()
        // Ajoute des données de test
        manager.favorites = [allProducts[0], allProducts[2]]
        
        return FavoritesView()
            .environmentObject(manager)
    }
}
