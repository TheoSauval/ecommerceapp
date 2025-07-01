//
//  APIConfig.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

// Enum pour les erreurs d'API personnalisées
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case noData
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide."
        case .requestFailed(let error):
            return error.localizedDescription
        case .invalidResponse:
            return "Réponse du serveur invalide."
        case .decodingError:
            return "Erreur de décodage des données."
        case .noData:
            return "Aucune donnée reçue du serveur."
        case .serverError(let message):
            return message
        }
    }
}

class APIConfig {
    static let shared = APIConfig() // Instance partagée (Singleton)
    
    // Configuration pour différents environnements
    #if DEBUG
    // En développement : utiliser ngrok pour tester sur iPhone
    static let baseURL = "https://crane-concrete-coyote.ngrok-free.app"
    #else
    // En production : utiliser votre serveur déployé
    static let baseURL = "https://votre-serveur-production.com"
    #endif
    
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