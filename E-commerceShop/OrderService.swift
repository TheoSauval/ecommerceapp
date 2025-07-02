//
//  OrderService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class OrderService {
    static let shared = OrderService()
    private let baseURL = "\(APIConfig.baseURL)/api/orders"
    
    // On retire la gestion locale du token pour toujours utiliser AuthService
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData
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
            
            // Vérifier d'abord si c'est une réponse d'erreur
            if let responseString = String(data: data, encoding: .utf8),
               responseString.contains("\"message\"") {
                
                // Essayer de décoder comme une erreur
                do {
                    let errorResponse = try JSONDecoder().decode(ServerErrorResponse.self, from: data)
                    print("❌ Erreur serveur détectée:", errorResponse.message)
                    completion(.failure(NSError(domain: "ServerError", code: 400, userInfo: [NSLocalizedDescriptionKey: errorResponse.message])))
                    return
                } catch {
                    print("⚠️ Impossible de décoder l'erreur, utilisation du message brut")
                    completion(.failure(NSError(domain: "ServerError", code: 400, userInfo: [NSLocalizedDescriptionKey: responseString])))
                    return
                }
            }
            
            // Si ce n'est pas une erreur, essayer de décoder comme une commande
            do {
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(.success(order))
            } catch {
                print("❌ Erreur lors du décodage de la commande:", error)
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
    
    func cancelOrder(orderId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(orderId)/cancel") else { 
            print("❌ URL invalide pour l'annulation: \(baseURL)/\(orderId)/cancel")
            return 
        }
        
        print("🔗 URL d'annulation: \(url)")
        let request = createRequest(url: url, method: "POST")
        
        // Log des headers pour debug
        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
            print("🔑 Token d'authentification présent: \(String(authHeader.prefix(20)))...")
        } else {
            print("❌ Pas de token d'authentification")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau lors de l'annulation: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Réponse HTTP: \(httpResponse.statusCode) \(httpResponse.statusCode == 200 ? "OK" : "Erreur")")
                
                if let data = data, let responseText = String(data: data, encoding: .utf8) {
                    print("📄 Corps de la réponse: \(responseText)")
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    print("✅ Annulation réussie")
                    completion(.success(()))
                } else {
                    print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                    completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode)))
                }
            } else {
                print("❌ Pas de réponse HTTP")
                completion(.failure(NSError(domain: "NoResponse", code: 0)))
            }
        }.resume()
    }
}
