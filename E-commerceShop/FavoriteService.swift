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
    private let endpoint = "/api/users/me/favorites"
    
    // Token d'authentification (à gérer avec AuthService)
    private var authToken: String?
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func getFavorites(completion: @escaping (Result<[Product], Error>) -> Void) {
        api.request(endpoint: endpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
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
        let body = ["product_id": productId]
        api.request(endpoint: endpoint, method: "POST", body: body) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func removeFavorite(productId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(endpoint: "\\(endpoint)/\\(productId)", method: "DELETE") { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 