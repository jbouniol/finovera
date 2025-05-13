//
//  Recommendation+Mock.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

/// Jeu de recommandations simulées (fallback hors-ligne et CI/CD)
extension Recommendation {
    static let mock: [Recommendation] = [
        .init(symbol: "AAPL", name: "Apple Inc.", score: 0.88, allocation: 2000, sector: "Technology", region: "United States", sentiment: 0.75),
        .init(symbol: "MSFT", name: "Microsoft", score: 0.85, allocation: 1800, sector: "Technology", region: "United States", sentiment: 0.68),
        .init(symbol: "NVDA", name: "NVIDIA Corp.", score: 0.82, allocation: 1500, sector: "Technology", region: "United States", sentiment: 0.72),
        .init(symbol: "GOOGL", name: "Alphabet Inc.", score: 0.79, allocation: 1400, sector: "Communication Services", region: "United States", sentiment: 0.63),
        .init(symbol: "AMZN", name: "Amazon.com Inc.", score: 0.77, allocation: 1300, sector: "Consumer Cyclical", region: "United States", sentiment: 0.61),
        .init(symbol: "AIR.PA", name: "Airbus SE", score: 0.78, allocation: 1200, sector: "Industrials", region: "Europe", sentiment: 0.55),
        .init(symbol: "TSLA", name: "Tesla Inc.", score: 0.74, allocation: 1100, sector: "Consumer Cyclical", region: "United States", sentiment: 0.48),
        .init(symbol: "JNJ", name: "Johnson & Johnson", score: 0.71, allocation: 1000, sector: "Healthcare", region: "United States", sentiment: 0.37),
        .init(symbol: "V", name: "Visa Inc.", score: 0.70, allocation: 950, sector: "Financial Services", region: "United States", sentiment: 0.42),
        .init(symbol: "JPM", name: "JPMorgan Chase & Co.", score: 0.68, allocation: 900, sector: "Financial Services", region: "United States", sentiment: 0.30)
    ]
    
    // Mock spécifique pour le portefeuille
    static let mockPortfolio: [Recommendation] = [
        .init(symbol: "AAPL", name: "Apple Inc.", score: 0.88, allocation: 2000, sector: "Technology", region: "United States", sentiment: 0.75),
        .init(symbol: "MSFT", name: "Microsoft", score: 0.85, allocation: 1800, sector: "Technology", region: "United States", sentiment: 0.68),
        .init(symbol: "TSLA", name: "Tesla Inc.", score: 0.74, allocation: 1100, sector: "Consumer Cyclical", region: "United States", sentiment: 0.48)
    ]
}
