import SwiftUI

struct HomeView: View {
    @EnvironmentObject var productViewModel: ProductViewModel

    let columns = [GridItem(.adaptive(minimum: 160))]

    var body: some View {
        NavigationView {
            Group {
                if productViewModel.isLoading {
                    ProgressView("Chargement des produits...")
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
                            ForEach(productViewModel.products) { product in
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
