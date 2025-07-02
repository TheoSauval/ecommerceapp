import SwiftUI

struct HomeView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    @StateObject private var categoryService = CategoryService()
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isRefreshing = false
    @State private var showRefreshSuccess = false

    let columns = [GridItem(.adaptive(minimum: 160))]

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
    
    func performRefresh() {
        isRefreshing = true
        
        // Rafraîchir les produits
        productViewModel.refreshProducts()
        
        // Rafraîchir les recommandations si l'utilisateur est connecté
        recommendationViewModel.refreshRecommendations()
        
        // Rafraîchir les catégories
        categoryService.refreshCategories()
        
        // Arrêter l'indicateur de rafraîchissement après un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
            showRefreshSuccess = true
            
            // Masquer le message de succès après 2 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showRefreshSuccess = false
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Message de confirmation de rafraîchissement
                if showRefreshSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Boutique rafraîchie avec succès !")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showRefreshSuccess)
                }
                
                SearchBar(placeholder: "Rechercher des articles...", text: $searchText)

                // Barre de filtres par catégorie
                if categoryService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Chargement des filtres...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categoryService.categories, id: \.self) { category in
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
                    .refreshable {
                        performRefresh()
                    }
                }
            }
            .navigationTitle("Boutique")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        performRefresh()
                    }) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .onAppear {
                if productViewModel.products.isEmpty {
                    productViewModel.fetchProducts()
                }
                
                // Charger les recommandations si l'utilisateur est connecté
                if recommendationViewModel.recommendations.isEmpty {
                    recommendationViewModel.fetchRecommendations()
                }
                
                // Les catégories sont automatiquement chargées par CategoryService
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
