//
//  AuthService.swift
//  E-commerceShop
//
//  Created by Théo Sauval on 05/06/2025.
//

import Foundation

class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://192.0.0.2:3000/api/auth"

    func register(
        nom: String, prenom: String, age: Int, mail: String, password: String,
        user: String = "user",
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "nom": nom,
            "prenom": prenom,
            "age": age,
            "mail": mail,
            "password": password,
            "user": user,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(.failure(NSError(domain: "InvalidData", code: 0)))
                return
            }
            completion(.success(json))
        }.resume()
    }

    func login(
        mail: String, password: String,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "mail": mail,
            "password": password,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(.failure(NSError(domain: "InvalidData", code: 0)))
                return
            }
            completion(.success(json))
        }.resume()
    }
}
