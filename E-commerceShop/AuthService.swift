//
//  AuthService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation
import SwiftUI

// Structures pour décoder la réponse de connexion
struct LoginResponse: Decodable {
    let session: SessionData
}

struct SessionData: Decodable {
    let access_token: String
    let refresh_token: String?
}

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var accessToken: String?
    private var refreshToken: String?

    private let api = APIConfig.shared
    
    private let baseURL = APIConfig.baseURL
    
    private init() {
        loadTokens()
    }

    private func createRequest(url: URL, method: String, needsAuth: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if needsAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Authentication Methods

    func register(email: String, password: String, firstName: String?, lastName: String?, age: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/register") else { return }
        
        var request = createRequest(url: url, method: "POST", needsAuth: false)
        
        var body: [String: Any] = [
            "mail": email,
            "password": password,
            "age": age,
            "role": "user",
            "nom": lastName ?? "",
            "prenom": firstName ?? ""
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(APIError.serverError(message: errorResponse.message)))
                    } else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        completion(.failure(APIError.requestFailed(NSError(domain: "AuthError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(statusCode)"]))))
                    }
                    return
                }
                
                completion(.success(()))
            }
        }.resume()
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else { return }
        
        var request = createRequest(url: url, method: "POST", needsAuth: false)
        let body: [String: Any] = ["mail": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    var message = "Erreur de connexion (code: \(statusCode))"
                    if statusCode == 401 || statusCode == 400 {
                        message = "Email ou mot de passe incorrect."
                    } else if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        message = errorResponse.message
                    }
                    self?.errorMessage = message
                    completion(.failure(APIError.serverError(message: message)))
                    return
                }
                
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    let authTokens = AuthTokens(
                        accessToken: loginResponse.session.access_token,
                        refreshToken: loginResponse.session.refresh_token
                    )
                    self?.handleSuccessfulAuth(tokens: authTokens)
                    completion(.success(()))
                } catch {
                    self?.errorMessage = "Échec du décodage des tokens: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func logout() {
        // Vous pouvez également appeler un endpoint /api/auth/logout ici
        // pour invalider le token côté serveur.
        clearTokens()
    }
    
    // MARK: - Token Management

    private func handleSuccessfulAuth(tokens: AuthTokens) {
        self.accessToken = tokens.accessToken
        self.refreshToken = tokens.refreshToken
        self.isAuthenticated = true
        saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken ?? "")
    }

    private func loadTokens() {
        if let token = getAccessToken() {
            self.accessToken = token
            self.isAuthenticated = true
            // Ici, vous pourriez ajouter une logique pour vérifier si le token est toujours valide
        }
    }

    private func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
    }

    private func clearTokens() {
        accessToken = nil
        refreshToken = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
    }
    
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    private func extractErrorMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let message):
                return message
            case .requestFailed(let underlyingError):
                return underlyingError.localizedDescription
            case .decodingError:
                return "Erreur de décodage des données."
            default:
                return "Une erreur d'API est survenue."
            }
        }
        return error.localizedDescription
    }
}
