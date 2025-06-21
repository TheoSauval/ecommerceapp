//
//  ProductService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

// Structure pour décoder la réponse de l'API des produits
struct ProductsResponse: Decodable {
    let products: [Product]
}

struct ProductService {
    private let api = APIConfig.shared
    
    // Récupère tous les produits
    func fetchAllProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        api.request(endpoint: "/api/products", method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    // Décoder la réponse complète
                    let response = try JSONDecoder().decode(ProductsResponse.self, from: data)
                    // Extraire le tableau de produits
                    completion(.success(response.products))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Récupère un seul produit par son ID
    func fetchProduct(byId id: Int, completion: @escaping (Result<Product, Error>) -> Void) {
        api.request(endpoint: "/api/products/\(id)", method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let product = try JSONDecoder().decode(Product.self, from: data)
                    completion(.success(product))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 