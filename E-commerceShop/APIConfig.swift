//
//  APIConfig.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

// Enum pour les erreurs d'API personnalisées
enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case noData
    case serverError(message: String)
}

class APIConfig {
    static let shared = APIConfig() // Instance partagée (Singleton)
    
    // Rendre baseURL accessible statiquement depuis d'autres services
    static let baseURL = "http://localhost:4000"
    
    private var authToken: String? {
        // Récupère le token depuis AuthService pour être toujours à jour
        return AuthService.shared.accessToken
    }

    private init() {} // Empêche la création d'autres instances

    func request(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        completion: @escaping (Result<Data?, Error>) -> Void
    ) {
        guard let url = URL(string: Self.baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Ajoute le token d'authentification s'il existe
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🚀 [API Request] \(method) to \(url.absoluteString)")

        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
                    print("📦 [API Request Body] \(bodyString)")
                }
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Log l'erreur brute s'il y en a une
                if let error = error {
                    print("🚨 [API Error] Request failed for \(url.absoluteString) with error: \(error.localizedDescription)")
                    completion(.failure(APIError.requestFailed(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("🚨 [API Error] Invalid response from \(url.absoluteString)")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                print("✅ [API Response] Status code: \(httpResponse.statusCode) from \(url.absoluteString)")

                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("📄 [API Response Data] \(dataString)")
                }

                if (200...299).contains(httpResponse.statusCode) {
                    completion(.success(data))
                } else {
                    if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(APIError.serverError(message: errorResponse.message)))
                    } else {
                        completion(.failure(APIError.invalidResponse))
                    }
                }
            }
        }.resume() // DÉMARRE LA REQUÊTE
    }
}

// Structure pour décoder les messages d'erreur du serveur
struct ErrorResponse: Decodable {
    let message: String
} 