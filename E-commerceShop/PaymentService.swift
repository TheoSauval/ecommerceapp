//
//  PaymentService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation
import UIKit

class PaymentService {
    static let shared = PaymentService()
    private let baseURL = "\(APIConfig.baseURL)/api/payments"
    
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
    
    func getPaymentById(id: String, completion: @escaping (Result<Payment, Error>) -> Void) {
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
    
    /// Initie un paiement Stripe pour une commande
    func initiateStripePayment(orderId: String, completion: @escaping (Result<StripeSessionResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/stripe/initiate") else { return }
        var request = createRequest(url: url, method: "POST")
        
        let body: [String: Any] = ["orderId": orderId]
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
            print("Réponse brute Stripe initiate:", String(data: data, encoding: .utf8) ?? "nil")
            do {
                let response = try JSONDecoder().decode(StripeSessionResponse.self, from: data)
                completion(.success(response))
            } catch {
                print("Erreur de décodage StripeSessionResponse:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Récupère le statut d'un paiement Stripe
    func getStripePaymentStatus(orderId: String, completion: @escaping (Result<StripePaymentStatus, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/stripe/\(orderId)/status") else { return }
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
                let status = try JSONDecoder().decode(StripePaymentStatus.self, from: data)
                completion(.success(status))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Ouvre l'interface de paiement Stripe dans Safari
    func openStripeCheckout(url: String) {
        guard let url = URL(string: url) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    /// Vérifie si l'utilisateur revient d'un paiement Stripe
    func handleStripeReturn(url: URL) -> Bool {
        guard url.absoluteString.contains("checkout.stripe.com") else { return false }
        
        // Extraire le session_id de l'URL si présent
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value {
            // Traiter le retour du paiement
            print("Retour du paiement Stripe avec session_id: \(sessionId)")
            return true
        }
        
        return false
    }
}

// MARK: - Modèles de réponse Stripe

struct StripeSessionResponse: Codable {
    let sessionId: String
    let url: String
}

struct StripePaymentStatus: Codable {
    let status: String
    let amount: Double?
    let currency: String?
}
