import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var productViewModel: ProductViewModel
    @EnvironmentObject var recommendationViewModel: RecommendationViewModel
    @Environment(\.colorScheme) var colorScheme

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
            (selectedColor == nil || variant.colors?.id == selectedColor?.id) &&
            (selectedSize == nil || variant.heights?.id == selectedSize?.id)
        } ?? variants.first
    }
    
    // Computed property pour obtenir les tailles disponibles pour la couleur sélectionnée
    private var availableSizesForSelectedColor: [ProductSize] {
        guard let selectedColor = selectedColor else {
            // Si aucune couleur n'est sélectionnée, retourner toutes les tailles
            return variants.compactMap { $0.heights }.removingDuplicates()
        }
        
        // Filtrer les variantes pour la couleur sélectionnée et extraire les tailles
        let sizesForColor = variants
            .filter { variant in
                variant.colors?.id == selectedColor.id && variant.stock > 0
            }
            .compactMap { $0.heights }
            .removingDuplicates()
        
        return sizesForColor
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)

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
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.secondary)
                            // Color Selection
                            let colors = variants.compactMap { $0.colors }.removingDuplicates()
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
                                                    // Réinitialiser la taille sélectionnée quand on change de couleur
                                                    selectedSize = nil
                                                }
                                        }
                                    }
                                }
                            }

                            // Size Selection - Maintenant filtrée par couleur
                            if !availableSizesForSelectedColor.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Taille").font(.headline)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(availableSizesForSelectedColor, id: \.id) { size in
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
                                .padding(.horizontal)
                            } else if selectedColor != nil {
                                // Afficher un message si aucune taille n'est disponible pour la couleur sélectionnée
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Taille").font(.headline)
                                    Text("Aucune taille disponible pour cette couleur")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .padding(.horizontal)
                            }
                            // Ajout d'un margin (espace) sous la sélection de taille
                            Spacer().frame(height: 4)
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
                                .background(colorScheme == .dark ? Color.white : Color.black)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                            }
                            .disabled(selectedVariant == nil)
                            .padding()
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            productViewModel.fetchProduct(id: product.id)
            
            // Démarrer le suivi de la durée de consultation
            recommendationViewModel.startViewTracking(productId: product.id)
        }
        .onDisappear {
            // Arrêter le suivi de la durée de consultation
            recommendationViewModel.stopViewTracking()
        }
        .onChange(of: variants) { newVariants in
            if selectedColor == nil {
                selectedColor = newVariants.first?.colors
            }
            if selectedSize == nil {
                selectedSize = newVariants.first?.heights
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
