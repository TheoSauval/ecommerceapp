import Foundation

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedProduct: Product?
    
    private let productService = ProductService()
    
    func fetchProducts() {
        isLoading = true
        errorMessage = nil
        
        productService.fetchAllProducts { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let products):
                    self?.products = products
                case .failure(let error):
                    self?.errorMessage = "Failed to load products: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchProduct(id: Int) {
        isLoading = true
        errorMessage = nil
        
        productService.fetchProduct(byId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let product):
                    self?.selectedProduct = product
                case .failure(let error):
                    self?.errorMessage = "Failed to load product details: \(error.localizedDescription)"
                }
            }
        }
    }
} 