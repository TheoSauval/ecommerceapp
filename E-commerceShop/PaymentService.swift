//
//  PaymentService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class PaymentService {
    static let shared = PaymentService()
    private let baseURL = "http://localhost:4000/api/payments"
    
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
    
    func getPayments(completion: @escaping (Result<[Payment], Error>) -> Void) {
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
                let payments = try JSONDecoder().decode([Payment].self, from: data)
                completion(.success(payments))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getPaymentById(id: Int, completion: @escaping (Result<Payment, Error>) -> Void) {
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
                let payment = try JSONDecoder().decode(Payment.self, from: data)
                completion(.success(payment))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func createPayment(paymentData: PaymentRequest, completion: @escaping (Result<Payment, Error>) -> Void) {
        guard let url = URL(string: baseURL) else { return }
        var request = createRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(paymentData)
        
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
                let payment = try JSONDecoder().decode(Payment.self, from: data)
                completion(.success(payment))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func processStripePayment(paymentIntentId: String, completion: @escaping (Result<Payment, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/stripe/confirm") else { return }
        var request = createRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "payment_intent_id": paymentIntentId
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
                let payment = try JSONDecoder().decode(Payment.self, from: data)
                completion(.success(payment))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}