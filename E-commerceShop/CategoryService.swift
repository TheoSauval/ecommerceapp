import Foundation

class CategoryService: ObservableObject {
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadCategories()
    }
    
    func loadCategories() {
        isLoading = true
        errorMessage = nil
        
        APIConfig.shared.request(endpoint: "/api/products/categories", method: "GET") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    if let data = data {
                        do {
                            let apiCategories = try JSONDecoder().decode([String].self, from: data)
                            
                            // Ajouter les filtres spéciaux au début
                            var allCategories = ["Tous", "Recommandations"]
                            
                            // Ajouter les catégories de la base de données
                            allCategories.append(contentsOf: apiCategories)
                            
                            self?.categories = allCategories
                            print("✅ \(apiCategories.count) catégories chargées depuis l'API")
                        } catch {
                            self?.errorMessage = "Erreur de décodage des données"
                            print("❌ Erreur de décodage des catégories: \(error)")
                            // En cas d'erreur, utiliser les catégories par défaut
                            self?.categories = ["Tous", "Recommandations", "T-Shirt", "Sweat", "Manteau"]
                        }
                    } else {
                        self?.errorMessage = "Aucune donnée reçue"
                        print("❌ Aucune donnée reçue pour les catégories")
                        // En cas d'erreur, utiliser les catégories par défaut
                        self?.categories = ["Tous", "Recommandations", "T-Shirt", "Sweat", "Manteau"]
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("❌ Erreur lors du chargement des catégories: \(error)")
                    // En cas d'erreur, utiliser les catégories par défaut
                    self?.categories = ["Tous", "Recommandations", "T-Shirt", "Sweat", "Manteau"]
                }
            }
        }
    }
    
    func refreshCategories() {
        loadCategories()
    }
} 