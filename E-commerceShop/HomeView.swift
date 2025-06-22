import SwiftUI

struct HomeView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var searchText = ""

    let columns = [GridItem(.adaptive(minimum: 160))]

    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return productViewModel.products
        } else {
            return productViewModel.products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(placeholder: "Rechercher des articles...", text: $searchText)

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
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(ProductViewModel())
            .environmentObject(CartManager())
            .environmentObject(FavoritesManager())
    }
}
