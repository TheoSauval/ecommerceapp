//
//  FavoriteService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class FavoriteService {
    static let shared = FavoriteService()
    private let api = APIConfig.shared
    private let endpoint = "/api/favorites" // Simplification de la route de base
    
    // Le token est géré directement par APIConfig via AuthService.shared
    // donc plus besoin de le stocker ou de le passer ici.
    
    private init() {} // Assure que seul un singleton peut être créé

    func getFavorites(completion: @escaping (Result<[Product], Error>) -> Void) {
        let fullEndpoint = "/api/users/me/favorites" // Endpoint complet pour cette requête
        api.request(endpoint: fullEndpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    // Correction: Le backend renvoie directement une liste de [Product]
                    let products = try JSONDecoder().decode([Product].self, from: data)
                    completion(.success(products))
                } catch {
                    completion(.failure(APIError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addFavorite(productId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let fullEndpoint = "/api/users/me/favorites" // Endpoint complet pour cette requête
        let body = ["product_id": productId]
        
        api.request(endpoint: fullEndpoint, method: "POST", body: body) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func removeFavorite(productId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // Construction de l'endpoint spécifique pour la suppression
        let fullEndpoint = "/api/users/me/favorites/\(productId)"
        
        api.request(endpoint: fullEndpoint, method: "DELETE") { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 