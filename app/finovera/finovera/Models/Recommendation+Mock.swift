//
//  Recommendation+Mock.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

/// Jeu de recommandations simulées (fallback hors-ligne)
extension Recommendation {
    static let mock: [Recommendation] = [
        .init(symbol: "AAPL", name: "Apple Inc.", score: 88, allocation: 2000, sector: "Technology", region: "US"),
        .init(symbol: "MSFT", name: "Microsoft", score: 85, allocation: 1800, sector: "Technology", region: "US"),
        .init(symbol: "NVDA", name: "NVIDIA Corp.", score: 82, allocation: 1500, sector: "Technology", region: "US"),
        .init(symbol: "AIR", name: "Airbus SE", score: 78, allocation: 1200, sector: "Aerospace", region: "Europe")
    ]
    
    // Mock spécifique pour le portefeuille avec uniquement Apple
    static let mockPortfolio: [Recommendation] = [
        .init(symbol: "AAPL", name: "Apple Inc.", score: 88, allocation: 2000, sector: "Technology", region: "US")
    ]
}
