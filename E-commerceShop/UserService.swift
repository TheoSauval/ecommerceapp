//
//  UserService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation
import Combine

class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var userProfile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let baseURL = "\(APIConfig.baseURL)/users"
    
    private func createRequest(url: URL, method: String, needsAuth: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if needsAuth, let token = AuthService.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func getProfile() {
        guard let url = URL(string: "\(baseURL)/me") else {
            self.errorMessage = "URL invalide"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: createRequest(url: url, method: "GET")) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Erreur réseau: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self?.errorMessage = "Erreur de serveur ou pas de données"
                    return
                }
                
                do {
                    let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                    self?.userProfile = profile
                } catch {
                    self?.errorMessage = "Erreur de décodage: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func updateProfile(profileData: UserProfileUpdate, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/me") else { return }
        var request = createRequest(url: url, method: "PUT")
        
        do {
            request.httpBody = try JSONEncoder().encode(profileData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "NoData", code: 0)))
                    return
                }
                
                do {
                    let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                    self.userProfile = profile // Mettre à jour le profil localement
                    completion(.success(profile))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func changePassword(passwordData: PasswordChange, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/me/password") else { return }
        var request = createRequest(url: url, method: "PUT")
        
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(passwordData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }.resume()
    }
    
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/me") else { return }
        let request = createRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }.resume()
    }
}