//
//  NotificationService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class NotificationService {
    static let shared = NotificationService()
    private let baseURL = "http://localhost:4000/api/notifications"
    
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
    
    func getNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        guard let url = URL(string: baseURL) else { return }
        let request = createRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            
            do {
                let notifications = try JSONDecoder().decode([Notification].self, from: data)
                completion(.success(notifications))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func markAsRead(notificationId: Int, completion: @escaping (Result<Notification, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(notificationId)") else { return }
        var request = createRequest(url: url, method: "PUT")
        
        let body: [String: Any] = [
            "lu": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            
            do {
                let notification = try JSONDecoder().decode(Notification.self, from: data)
                completion(.success(notification))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func markAllAsRead(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/mark-all-read") else { return }
        let request = createRequest(url: url, method: "PUT")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
}