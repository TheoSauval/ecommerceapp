import SwiftUI

struct FavoritesView: View {
    @Binding var favorites: [Product]
    @Binding var selectedTab: Int
    

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if favorites.isEmpty {
                    VStack {
                        Spacer()
                        Text("Aucun favori pour le moment.")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Spacer()
                    Text("Vos favoris")
                        .font(.headline)
                        .padding()
                        .padding(.top, 0)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(favorites) { product in
                            ProductCardView(product: product, favoriteProducts: $favorites, selectedTab: $selectedTab)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
