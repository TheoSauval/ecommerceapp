import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @State private var added = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(product.imageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)

                // 🔄 Nom + prix alignés sur la même ligne
                HStack {
                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Text("€\(String(format: "%.2f", product.prix))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text(product.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(product.description)
                    .font(.body)
                    .foregroundColor(.secondary)

                Button(action: {
                    cartManager.add(product)
                    withAnimation {
                        added = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            added = false
                        }
                    }
                }) {
                    Text(added ? "Ajouté au panier ✅" : "Ajouter au panier")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(added ? Color.green : Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Détail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProductDetailView(product: allProducts[0])
        .environmentObject(CartManager())
}
