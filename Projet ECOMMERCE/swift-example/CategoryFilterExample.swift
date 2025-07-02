import SwiftUI
import Foundation

// MARK: - Modèles de données
struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.name == rhs.name
    }
}

struct Product: Identifiable, Codable {
    let id: Int
    let nom: String
    let prix_base: Double
    let description: String?
    let categorie: String?
    let marque: String?
    let images: [String]?
    let variants: [ProductVariant]?
    
    enum CodingKeys: String, CodingKey {
        case id, nom, prix_base, description, categorie, marque, images, variants
    }
}

struct ProductVariant: Identifiable, Codable {
    let id: Int
    let stock: Int
    let prix: Double?
    let color: Color?
    let height: Height?
    
    enum CodingKeys: String, CodingKey {
        case id, stock, prix, colors, heights
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        stock = try container.decode(Int.self, forKey: .stock)
        prix = try container.decodeIfPresent(Double.self, forKey: .prix)
        
        // Décodage des relations
        if let colorData = try? container.decode(Color.self, forKey: .colors) {
            color = colorData
        } else {
            color = nil
        }
        
        if let heightData = try? container.decode(Height.self, forKey: .heights) {
            height = heightData
        } else {
            height = nil
        }
    }
}

struct Color: Codable {
    let id: Int
    let nom: String
    let code_hex: String?
}

struct Height: Codable {
    let id: Int
    let nom: String
    let ordre: Int?
}

struct ProductsResponse: Codable {
    let products: [Product]
    let totalPages: Int
    let currentPage: Int
    let category: String?
}

// MARK: - Service API
class ProductService: ObservableObject {
    private let baseURL = "http://localhost:3000/api"
    
    @Published var categories: [Category] = []
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var currentCategory: Category?
    @Published var totalPages = 0
    @Published var currentPage = 1
    
    init() {
        loadCategories()
    }
    
    // Charger toutes les catégories disponibles
    func loadCategories() {
        guard let url = URL(string: "\(baseURL)/products/categories") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data, let categories = try? JSONDecoder().decode([String].self, from: data) {
                    // Ajouter les filtres spéciaux
                    var allCategories: [Category] = [
                        Category(name: "Tous"),
                        Category(name: "Recommandations")
                    ]
                    
                    // Ajouter les catégories de la base de données
                    allCategories.append(contentsOf: categories.map { Category(name: $0) })
                    
                    self?.categories = allCategories
                }
            }
        }.resume()
    }
    
    // Charger les produits par catégorie
    func loadProducts(category: Category, page: Int = 1) {
        isLoading = true
        currentCategory = category
        
        var urlString: String
        
        switch category.name {
        case "Tous":
            urlString = "\(baseURL)/products?page=\(page)"
        case "Recommandations":
            urlString = "\(baseURL)/recommendations?page=\(page)"
        default:
            // Encoder la catégorie pour l'URL
            let encodedCategory = category.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category.name
            urlString = "\(baseURL)/products/category/\(encodedCategory)?page=\(page)"
        }
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let data = data {
                    if let response = try? JSONDecoder().decode(ProductsResponse.self, from: data) {
                        if page == 1 {
                            self?.products = response.products
                        } else {
                            self?.products.append(contentsOf: response.products)
                        }
                        self?.totalPages = response.totalPages
                        self?.currentPage = response.currentPage
                    } else if let products = try? JSONDecoder().decode([Product].self, from: data) {
                        // Pour les recommandations qui peuvent retourner un format différent
                        if page == 1 {
                            self?.products = products
                        } else {
                            self?.products.append(contentsOf: products)
                        }
                    }
                }
            }
        }.resume()
    }
    
    // Charger plus de produits (pagination)
    func loadMoreProducts() {
        guard let category = currentCategory, currentPage < totalPages else { return }
        loadProducts(category: category, page: currentPage + 1)
    }
}

// MARK: - Vue principale avec filtres
struct ProductListView: View {
    @StateObject private var productService = ProductService()
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de filtres horizontale
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(productService.categories) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategory?.name == category.name
                            ) {
                                selectedCategory = category
                                productService.loadProducts(category: category)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                // Liste des produits
                if productService.isLoading && productService.products.isEmpty {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(productService.products) { product in
                                ProductCard(product: product)
                                    .onAppear {
                                        // Charger plus de produits quand on arrive à la fin
                                        if product.id == productService.products.last?.id {
                                            productService.loadMoreProducts()
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Produits")
            .onAppear {
                if selectedCategory == nil && !productService.categories.isEmpty {
                    selectedCategory = productService.categories.first
                    productService.loadProducts(category: selectedCategory!)
                }
            }
        }
    }
}

// MARK: - Composant bouton de filtre
struct CategoryFilterButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Composant carte produit
struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image du produit (placeholder)
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 200)
                .overlay(
                    Text("Image")
                        .foregroundColor(.gray)
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.nom)
                    .font(.headline)
                    .lineLimit(2)
                
                if let categorie = product.categorie {
                    Text(categorie)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(String(format: "%.2f", product.prix_base)) €")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Prévisualisation
struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
    }
} 