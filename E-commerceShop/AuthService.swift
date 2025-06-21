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
    
    private init() {
        loadTokens()
    }

    // MARK: - Authentication Methods

    func register(nom: String, prenom: String, age: Int, mail: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let body: [String: Any] = [
            "nom": nom,
            "prenom": prenom,
            "age": age,
            "mail": mail,
            "password": password,
            "role": "user"
        ]
        
        api.request(endpoint: "/api/auth/register", method: "POST", body: body) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    let message = self?.extractErrorMessage(from: error) ?? "Une erreur inconnue est survenue."
                    self?.errorMessage = message
                    completion(.failure(NSError(domain: "RegisterError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            }
        }
    }

    func login(mail: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil

        let body: [String: Any] = ["mail": mail, "password": password]

        api.request(endpoint: "/api/auth/login", method: "POST", body: body) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    guard let data = data else {
                        let error = APIError.noData
                        self?.errorMessage = self?.extractErrorMessage(from: error)
                        completion(.failure(error))
                        return
                    }
                    do {
                        // Décoder la structure de réponse complète
                        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                        // Créer l'objet AuthTokens attendu par la méthode de gestion
                        let authTokens = AuthTokens(
                            accessToken: loginResponse.session.access_token,
                            refreshToken: loginResponse.session.refresh_token
                        )
                        self?.handleSuccessfulAuth(tokens: authTokens)
                        completion(.success(()))
                    } catch {
                        self?.errorMessage = "Échec du décodage des tokens: \(error.localizedDescription)"
                        print("🚨 [Decoding Error] \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    let message = self?.extractErrorMessage(from: error) ?? "Une erreur inconnue est survenue."
                    self?.errorMessage = message
                    completion(.failure(NSError(domain: "LoginError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            }
        }
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
    
    private func getAccessToken() -> String? {
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
