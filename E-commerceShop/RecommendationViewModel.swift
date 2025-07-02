//
//  RecommendationViewModel.swift
//  E-commerceShop
//
//  Created by Assistant on 06/06/2025.
//

import Foundation
import SwiftUI
import Combine

class RecommendationViewModel: ObservableObject {
    private let recommendationService = RecommendationService()
    
    @Published var recommendations: [Recommendation] = []
    @Published var userHistory: [HistoryItem] = []
    @Published var popularProducts: [PopularProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var categoryPreferences: [CategoryPreference] = []
    @Published var userAnalytics: UserAnalytics?
    
    // Timer pour suivre la durée de consultation
    private var viewTimer: Timer?
    private var currentProductId: Int?
    private var viewStartTime: Date?
    
    init() {
        // Charger les recommandations au démarrage
        fetchRecommendations()
    }
    
    // MARK: - Charger les recommandations
    
    func fetchRecommendations(limit: Int = 10) {
        isLoading = true
        errorMessage = nil
        
        recommendationService.fetchRecommendations(limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let recommendations):
                    self?.recommendations = recommendations
                    print("✅ \(recommendations.count) recommandations récupérées")
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("❌ Erreur récupération recommandations: \(error)")
                }
            }
        }
    }
    
    func refreshRecommendations(limit: Int = 10) {
        // Force le rafraîchissement même si des recommandations sont déjà chargées
        isLoading = true
        errorMessage = nil
        
        recommendationService.fetchRecommendations(limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let recommendations):
                    self?.recommendations = recommendations
                    print("✅ \(recommendations.count) recommandations rafraîchies avec succès")
                case .failure(let error):
                    self?.errorMessage = "Erreur lors du rafraîchissement des recommandations: \(error.localizedDescription)"
                    print("❌ Erreur lors du rafraîchissement des recommandations: \(error)")
                }
            }
        }
    }
    
    // MARK: - Charger l'historique utilisateur
    
    func fetchUserHistory() {
        isLoading = true
        errorMessage = nil
        
        recommendationService.fetchUserHistory { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let history):
                    self?.userHistory = history
                case .failure(let error):
                    self?.errorMessage = "Erreur lors du chargement de l'historique: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Charger les produits populaires
    
    func fetchPopularProducts() {
        isLoading = true
        errorMessage = nil
        
        recommendationService.fetchPopularProducts { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let products):
                    self?.popularProducts = products
                case .failure(let error):
                    self?.errorMessage = "Erreur lors du chargement des produits populaires: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Enregistrer une consultation
    
    func recordProductView(productId: Int) {
        recommendationService.recordProductView(productId: productId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Consultation enregistrée pour le produit \(productId)")
                case .failure(let error):
                    print("❌ Erreur enregistrement consultation: \(error)")
                }
            }
        }
    }
    
    // MARK: - Supprimer l'historique
    
    func deleteHistory() {
        isLoading = true
        errorMessage = nil
        
        recommendationService.deleteHistory { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(_):
                    self?.userHistory = []
                    self?.fetchRecommendations() // Recharger les recommandations
                case .failure(let error):
                    self?.errorMessage = "Erreur lors de la suppression de l'historique: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Convertir les recommandations en produits pour l'affichage
    
    var recommendationProducts: [Product] {
        return recommendations.map { recommendation in
            Product(
                id: recommendation.id,
                name: recommendation.name,
                category: recommendation.categorie ?? "Général",
                imageName: recommendation.imageName,
                prix: recommendation.prix,
                rating: recommendation.rating,
                description: recommendation.description ?? ""
            )
        }
    }
    
    var popularProductItems: [Product] {
        return popularProducts.map { popular in
            Product(
                id: popular.id,
                name: popular.name,
                category: popular.categorie ?? "Général",
                imageName: popular.imageName,
                prix: popular.prix,
                rating: popular.rating,
                description: popular.description ?? ""
            )
        }
    }
    
    var historyProducts: [Product] {
        return userHistory.compactMap { historyItem in
            guard let product = historyItem.products else { return nil }
            return product
        }
    }
    
    // MARK: - Vérifier si l'utilisateur a des recommandations
    
    var hasRecommendations: Bool {
        return !recommendations.isEmpty
    }
    
    var hasHistory: Bool {
        return !userHistory.isEmpty
    }
    
    var hasPopularProducts: Bool {
        return !popularProducts.isEmpty
    }
    
    // MARK: - Gestion de la durée de consultation
    
    /// Démarre le suivi de la durée de consultation pour un produit
    func startViewTracking(productId: Int) {
        // Arrêter le timer précédent s'il existe
        stopViewTracking()
        
        currentProductId = productId
        viewStartTime = Date()
        
        // Créer un timer qui s'exécute toutes les 30 secondes pour plus de précision
        viewTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateViewDuration()
        }
        
        // Enregistrer la consultation initiale
        recordProductView(productId: productId)
    }
    
    /// Arrête le suivi de la durée de consultation
    func stopViewTracking() {
        viewTimer?.invalidate()
        viewTimer = nil
        
        // Mettre à jour la durée finale
        updateViewDuration()
        
        currentProductId = nil
        viewStartTime = nil
    }
    
    /// Met à jour la durée de consultation
    private func updateViewDuration() {
        guard let productId = currentProductId,
              let startTime = viewStartTime else { return }
        
        let duration = Int(Date().timeIntervalSince(startTime))
        
        recommendationService.updateViewDuration(productId: productId, durationSeconds: duration) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Durée de consultation mise à jour: \(duration) secondes")
                case .failure(let error):
                    print("❌ Erreur mise à jour durée: \(error)")
                }
            }
        }
    }
    
    // MARK: - API Calls
    
    func fetchCategoryPreferences() {
        recommendationService.fetchCategoryPreferences { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let preferences):
                    self?.categoryPreferences = preferences
                    print("✅ \(preferences.count) préférences de catégories récupérées")
                case .failure(let error):
                    print("❌ Erreur récupération préférences: \(error)")
                }
            }
        }
    }
    
    func fetchUserAnalytics() {
        recommendationService.fetchUserAnalytics { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analytics):
                    self?.userAnalytics = analytics
                    print("✅ Analytics utilisateur récupérées")
                case .failure(let error):
                    print("❌ Erreur récupération analytics: \(error)")
                }
            }
        }
    }
    
    // MARK: - Utilitaires
    
    /// Retourne la catégorie préférée de l'utilisateur
    var favoriteCategory: String? {
        return categoryPreferences.first?.categorie
    }
    
    /// Retourne le score moyen des recommandations
    var averageRecommendationScore: Double {
        guard !recommendations.isEmpty else { return 0.0 }
        let totalScore = recommendations.reduce(0) { $0 + $1.score_recommendation }
        return totalScore / Double(recommendations.count)
    }
    
    /// Retourne les recommandations groupées par raison
    var recommendationsByReason: [String: [Recommendation]] {
        Dictionary(grouping: recommendations) { recommendation in
            // Extraire la raison du score (simulation - à adapter selon votre logique)
            if recommendation.score_recommendation > 0.8 {
                return "Catégorie préférée"
            } else if recommendation.score_recommendation > 0.5 {
                return "Produit populaire"
            } else {
                return "Nouveau produit"
            }
        }
    }
    
    /// Retourne les statistiques de consultation
    var consultationStats: String {
        guard let analytics = userAnalytics else { return "Aucune donnée" }
        
        let totalMinutes = analytics.totalDuration / 60
        let avgMinutes = analytics.avgSessionDuration / 60
        
        return "\(analytics.totalViews) consultations • \(totalMinutes) min total • \(String(format: "%.1f", avgMinutes)) min/session"
    }
    
    // MARK: - Nettoyage
    
    deinit {
        stopViewTracking()
    }
} 