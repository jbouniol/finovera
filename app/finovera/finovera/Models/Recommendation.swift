//
//  Recommendation.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

struct Recommendation: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let score: Double
    let allocation: Double
    let sector: String
    let region: String
    let sentiment: Double?
    
    // Pour rétrocompatibilité avec le code existant
    var reason: String {
        "Score: \(Int(score))/100 • Sector: \(sector) • Region: \(region)"
    }
    
    // Détermine l'action recommandée en fonction du score
    var recommendedAction: String {
        if score >= 0.6 {
            return "Renforcer"
        } else if score >= 0.4 {
            return "Garder"
        } else {
            return "Vendre"
        }
    }
    
    // Formate le sentiment en texte lisible
    var sentimentLabel: String {
        guard let sentiment = sentiment else { return "Neutre" }
        
        if sentiment >= 0.5 {
            return "Très positif"
        } else if sentiment >= 0.2 {
            return "Modérément positif"
        } else if sentiment >= 0 {
            return "Neutre"
        } else {
            return "Négatif"
        }
    }
}

