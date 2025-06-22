import SwiftUI

struct ProductCardView: View {
    let product: Product
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    @State private var showUnavailableAlert = false
    @StateObject private var productViewModel = ProductViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image du produit avec le bouton favori en superposition
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.images?.first ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Bouton Favori
                Button(action: {
                    // Logique de bascule pour les favoris
                    if favoritesManager.isFavorite(product) {
                        favoritesManager.removeFromFavorites(product)
                    } else {
                        favoritesManager.addToFavorites(product)
                    }
                }) {
                    Image(systemName: favoritesManager.isFavorite(product) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesManager.isFavorite(product) ? .red : .gray)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(10)
            }

            // Détails du produit
            NavigationLink(destination: ProductDetailView(product: product)) {
                VStack(alignment: .leading) {
                    Text(product.nom)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(product.categorie ?? "N/A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())


            // Prix et bouton d'ajout au panier
            HStack {
                Text("€\(String(format: "%.2f", product.prix_base))")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // La logique est corrigée pour utiliser `selectedProduct` qui est la bonne variable du ViewModel
                    if let firstVariant = productViewModel.selectedProduct?.product_variants?.first {
                        cartManager.addToCart(variantId: firstVariant.id)
                        viewRouter.currentTab = .cart
                    } else {
                        showUnavailableAlert = true
                    }
                }) {
                    Image(systemName: "cart.badge.plus")
                        .padding(8)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
        .onAppear(perform: fetchProductDetails)
        .alert("Produit indisponible", isPresented: $showUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ce produit n'a pas d'options disponibles et ne peut pas être ajouté au panier pour le moment.")
        }
    }
    
    private func fetchProductDetails() {
        productViewModel.fetchProduct(id: product.id)
    }
}

struct ProductCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Créez une instance de produit factice pour la prévisualisation
        let sampleProduct = Product(
            name: "T-Shirt de Designer",
            category: "Vêtements",
            imageName: "T-shirt_blanc", // Assurez-vous que cette image existe dans vos assets
            prix: 39.99,
            rating: 4.5,
            description: "Un t-shirt stylé de notre dernière collection."
        )
        
        ProductCardView(product: sampleProduct)
            .environmentObject(CartManager())
            .environmentObject(FavoritesManager())
            .environmentObject(ViewRouter())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
