import SwiftUI

struct HomeView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    let columns = [GridItem(.adaptive(minimum: 160))]

    // Liste des catégories à filtrer avec recommandations
    let categories = ["Tous", "Recommandations", "T-Shirt", "Sweat", "Manteau"]

    var filteredProducts: [Product] {
        // Si "Recommandations" est sélectionné, utiliser les recommandations
        if selectedCategory == "Recommandations" {
            return recommendationViewModel.recommendationProducts.filter { product in
                searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sinon, filtrer les produits normaux
        return productViewModel.products.filter { product in
            let matchSearch = searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            let matchCategory = (selectedCategory == nil || selectedCategory == "Tous") || (product.categorie?.localizedCaseInsensitiveContains(selectedCategory ?? "") ?? false)
            return matchSearch && matchCategory
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(placeholder: "Rechercher des articles...", text: $searchText)

                // Barre de filtres par catégorie
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = (category == "Tous") ? nil : category
                            }) {
                                Text(category)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background((selectedCategory == category || (selectedCategory == nil && category == "Tous")) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor((selectedCategory == category || (selectedCategory == nil && category == "Tous")) ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }

                if productViewModel.isLoading && productViewModel.products.isEmpty {
                    Spacer()
                    ProgressView("Chargement des produits...")
                    Spacer()
                } else if let errorMessage = productViewModel.errorMessage {
                    VStack {
                        Text("Erreur de chargement")
                        Text(errorMessage).foregroundColor(.gray)
                        Button("Réessayer") {
                            productViewModel.fetchProducts()
                        }
                    }
                } else if selectedCategory == "Recommandations" && recommendationViewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement des recommandations...")
                    Spacer()
                } else if selectedCategory == "Recommandations" && recommendationViewModel.errorMessage != nil {
                    VStack {
                        Text("Erreur de chargement des recommandations")
                        Text(recommendationViewModel.errorMessage!).foregroundColor(.gray)
                        Button("Réessayer") {
                            recommendationViewModel.fetchRecommendations()
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredProducts) { product in
                                ProductCardView(product: product)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Boutique")
            .onAppear {
                if productViewModel.products.isEmpty {
                    productViewModel.fetchProducts()
                }
                
                // Charger les recommandations si l'utilisateur est connecté
                if recommendationViewModel.recommendations.isEmpty {
                    recommendationViewModel.fetchRecommendations()
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ProductViewModel())
            .environmentObject(RecommendationViewModel())
            .environmentObject(CartManager())
            .environmentObject(FavoritesManager())
    }
}
