import SwiftUI

struct ProductCardView: View {
    let product: Product
    @Binding var favoriteProducts: [Product]
    @Binding var selectedTab: Int

    @State private var added = false // ✅ État pour l'effet visuel
    @EnvironmentObject var cartManager: CartManager

    var isFavorite: Bool {
        favoriteProducts.contains(where: { $0.id == product.id })
    }

    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(product.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)

                    Button(action: {
                        withAnimation {
                            toggleFavorite()
                        }
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .black)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle()) // évite bug dans NavigationLink
                }

                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                Text(product.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 4) {
                    Text("€\(String(format: "%.2f", product.prix))")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text(String(format: "%.1f", product.rating))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Button(action: {
                    cartManager.add(product)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(added ? Color.green : Color.black)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleFavorite() {
        if let index = favoriteProducts.firstIndex(where: { $0.id == product.id }) {
            favoriteProducts.remove(at: index)
        } else {
            favoriteProducts.append(product)
        }
    }
}
