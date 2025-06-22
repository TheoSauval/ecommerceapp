import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var productViewModel: ProductViewModel

    // State for variant selection
    @State private var selectedColor: ProductColor?
    @State private var selectedSize: ProductSize?
    
    private var displayedProduct: Product? {
        productViewModel.selectedProduct ?? product
    }
    
    private var variants: [ProductVariant] {
        productViewModel.selectedProduct?.product_variants ?? []
    }

    private var selectedVariant: ProductVariant? {
        variants.first { variant in
            (selectedColor == nil || variant.color?.id == selectedColor?.id) &&
            (selectedSize == nil || variant.height?.id == selectedSize?.id)
        } ?? variants.first
    }

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            ScrollView {
                if let p = displayedProduct {
                    VStack(alignment: .leading, spacing: 16) {
                        // Image
                        AsyncImage(url: URL(string: p.imageName)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)

                        // Name and favorite
                        HStack {
                            Text(p.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                if favoritesManager.isFavorite(p) {
                                    favoritesManager.removeFromFavorites(p)
                                } else {
                                    favoritesManager.addToFavorites(p)
                                }
                            }) {
                                Image(systemName: favoritesManager.isFavorite(p) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(favoritesManager.isFavorite(p) ? .red : .gray)
                            }
                        }

                        // Category and Rating
                        HStack {
                            Text(p.categorie ?? "N/A")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            HStack {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", p.rating))
                            }
                            .foregroundColor(.orange)
                        }

                        // Description
                        Text(p.description ?? "Aucune description.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Variant selection
                        if productViewModel.isLoading {
                            ProgressView()
                        } else if !variants.isEmpty {
                            Divider()
                            // Color Selection
                            let colors = variants.compactMap { $0.color }.removingDuplicates()
                            if !colors.isEmpty {
                                Text("Couleur").font(.headline)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(colors, id: \.id) { color in
                                            Circle()
                                                .fill(Color(hex: color.code_hex ?? "#FFFFFF"))
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Circle().stroke(selectedColor?.id == color.id ? Color.blue : Color.gray, lineWidth: 2)
                                                )
                                                .onTapGesture {
                                                    selectedColor = color
                                                }
                                        }
                                    }
                                }
                            }

                            // Size Selection
                            let sizes = variants.compactMap { $0.height }.removingDuplicates()
                            if !sizes.isEmpty {
                                Text("Taille").font(.headline)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(sizes, id: \.id) { size in
                                            Text(size.nom)
                                                .padding()
                                                .background(selectedSize?.id == size.id ? Color.gray.opacity(0.2) : Color.clear)
                                                .cornerRadius(8)
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                                                .onTapGesture {
                                                    selectedSize = size
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }

            // Add to cart button - only shown if variants are available
            if !variants.isEmpty {
                VStack {
                    Spacer()
                    Button(action: {
                        if let variant = selectedVariant {
                            cartManager.addToCart(variantId: variant.id)
                        }
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Ajouter au panier")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedVariant != nil ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                    }
                    .disabled(selectedVariant == nil)
                    .padding()
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            productViewModel.fetchProduct(id: product.id)
        }
        .onChange(of: variants) { newVariants in
            if selectedColor == nil {
                selectedColor = newVariants.first?.color
            }
            if selectedSize == nil {
                selectedSize = newVariants.first?.height
            }
        }
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}


struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(product: allProducts[0])
            .environmentObject(CartManager())
            .environmentObject(FavoritesManager())
            .environmentObject(ProductViewModel())
    }
}
