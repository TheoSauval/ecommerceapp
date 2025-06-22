import SwiftUI

struct ProductCardView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var showUnavailableAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ProductDetailView(product: product)) {
                VStack(alignment: .leading, spacing: 8) {
                    // Product Image
                    AsyncImage(url: URL(string: product.imageName)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Product Details
                    Text(product.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(product.categorie ?? "N/A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Price and Add to Cart
            HStack {
                Text("€\(String(format: "%.2f", product.prix))")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    if let variantId = product.product_variants?.first?.id {
                        cartManager.addToCart(variantId: variantId)
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
        .alert("Produit indisponible", isPresented: $showUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ce produit n'a pas d'options disponibles et ne peut pas être ajouté au panier pour le moment.")
        }
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
