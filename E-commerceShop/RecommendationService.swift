//
//  RecommendationService.swift
//  E-commerceShop
//
//  Created by Assistant on 06/06/2025.
//

import Foundation

// Structure pour décoder les réponses de l'API des recommandations
struct RecommendationsResponse: Decodable {
    let success: Bool
    let data: [Recommendation]
    let count: Int
}

struct HistoryResponse: Decodable {
    let success: Bool
    let data: [HistoryItem]
    let count: Int
}

struct PopularProductsResponse: Decodable {
    let success: Bool
    let data: [PopularProduct]
    let count: Int
}

struct ProductStatsResponse: Decodable {
    let success: Bool
    let data: ProductStats
}

struct CategoryPreferencesResponse: Decodable {
    let success: Bool
    let data: [CategoryPreference]
    let count: Int
}

struct UserAnalyticsResponse: Decodable {
    let success: Bool
    let data: UserAnalytics
}

class RecommendationService {
    private let api = APIConfig.shared
    
    // MARK: - Enregistrer une consultation de produit
    
    func recordProductView(productId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let requestBody: [String: Any] = ["productId": productId]
        
        api.request(endpoint: "/api/recommendations/view", method: "POST", body: requestBody) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Mettre à jour la durée de consultation
    
    func updateViewDuration(productId: Int, durationSeconds: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let requestBody: [String: Any] = [
            "productId": productId,
            "durationSeconds": durationSeconds
        ]
        
        api.request(endpoint: "/api/recommendations/duration", method: "PUT", body: requestBody) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer les recommandations
    
    func fetchRecommendations(limit: Int = 10, completion: @escaping (Result<[Recommendation], Error>) -> Void) {
        let endpoint = "/api/recommendations?limit=\(limit)"
        
        api.request(endpoint: endpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer les préférences de catégories
    
    func fetchCategoryPreferences(completion: @escaping (Result<[CategoryPreference], Error>) -> Void) {
        api.request(endpoint: "/api/recommendations/categories", method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(CategoryPreferencesResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer les analytics utilisateur
    
    func fetchUserAnalytics(completion: @escaping (Result<UserAnalytics, Error>) -> Void) {
        api.request(endpoint: "/api/recommendations/analytics", method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(UserAnalyticsResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer l'historique de consultation
    
    func fetchUserHistory(limit: Int = 20, completion: @escaping (Result<[HistoryItem], Error>) -> Void) {
        let endpoint = "/api/recommendations/history?limit=\(limit)"
        
        api.request(endpoint: endpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(HistoryResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer les produits populaires
    
    func fetchPopularProducts(limit: Int = 10, completion: @escaping (Result<[PopularProduct], Error>) -> Void) {
        let endpoint = "/api/recommendations/popular?limit=\(limit)"
        
        api.request(endpoint: endpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(PopularProductsResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Récupérer les statistiques d'un produit
    
    func fetchProductStats(productId: Int, completion: @escaping (Result<ProductStats, Error>) -> Void) {
        let endpoint = "/api/recommendations/stats/\(productId)"
        
        api.request(endpoint: endpoint, method: "GET") { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                do {
                    let response = try JSONDecoder().decode(ProductStatsResponse.self, from: data)
                    completion(.success(response.data))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Supprimer l'historique
    
    func deleteHistory(completion: @escaping (Result<Void, Error>) -> Void) {
        api.request(endpoint: "/api/recommendations/history", method: "DELETE") { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 