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
    
    // Pour rétrocompatibilité avec le code existant
    var reason: String {
        "Score: \(Int(score))/100 • Sector: \(sector) • Region: \(region)"
    }
}

