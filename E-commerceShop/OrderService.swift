//
//  OrderService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class OrderService {
    static let shared = OrderService()
    private let baseURL = "http://localhost:4000/api/orders"
    
    // On retire la gestion locale du token pour toujours utiliser AuthService
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
    
    func getOrders(completion: @escaping (Result<[Order], Error>) -> Void) {
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
                let orders = try JSONDecoder().decode([Order].self, from: data)
                completion(.success(orders))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getOrderById(id: Int, completion: @escaping (Result<Order, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(id)") else { return }
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
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(.success(order))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createOrder(orderData: OrderRequestBackend, completion: @escaping (Result<Order, Error>) -> Void) {
        guard let url = URL(string: baseURL) else { return }
        var request = createRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        if let body = try? encoder.encode(orderData) {
            print("Body envoyé:", String(data: body, encoding: .utf8) ?? "nil")
        }
        request.httpBody = try? encoder.encode(orderData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("Réponse vide du backend !")
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            print("Réponse brute backend:", String(data: data, encoding: .utf8) ?? "nil")
            do {
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(.success(order))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func updateOrderStatus(id: Int, status: String, completion: @escaping (Result<Order, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(id)") else { return }
        var request = createRequest(url: url, method: "PUT")
        
        let body: [String: Any] = [
            "status": status
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
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(.success(order))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}