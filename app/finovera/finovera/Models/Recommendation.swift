//
//  Recommendation.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation
import SwiftUI

struct Recommendation: Identifiable, Codable, Equatable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let region: String
    let sector: String
    let score: Double  // 0-1 score
    let recommendedAction: String
    let allocation: Double
    let sentiment: Double?
    
    // Decodable initializer with default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        region = try container.decode(String.self, forKey: .region)
        sector = try container.decode(String.self, forKey: .sector)
        score = try container.decode(Double.self, forKey: .score)
        recommendedAction = try container.decodeIfPresent(String.self, forKey: .recommendedAction) ?? "Garder"
        allocation = try container.decodeIfPresent(Double.self, forKey: .allocation) ?? 0.0
        sentiment = try container.decodeIfPresent(Double.self, forKey: .sentiment)
    }
    
    // Manual initializer for creating mock data
    init(symbol: String, name: String, region: String, sector: String, score: Double, recommendedAction: String, allocation: Double, sentiment: Double? = nil) {
        self.symbol = symbol
        self.name = name
        self.region = region
        self.sector = sector
        self.score = score
        self.recommendedAction = recommendedAction
        self.allocation = allocation
        self.sentiment = sentiment
    }
    
    // Pour rétrocompatibilité avec le code existant
    var reason: String {
        "Score: \(Int(score * 100))/100 • Secteur: \(sector) • Région: \(region)"
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
    
    // Badge de qualité pour la recommandation
    var qualityBadge: String {
        if score >= 0.9 {
            return "Excellent"
        } else if score >= 0.8 {
            return "Très bon"
        } else if score >= 0.7 {
            return "Bon"
        } else if score >= 0.6 {
            return "Moyen"
        } else if score >= 0.5 {
            return "Passable"
        } else {
            return "Risqué"
        }
    }
    
    // Couleur associée à la qualité
    var qualityColor: Color {
        if score >= 0.9 {
            return .green
        } else if score >= 0.8 {
            return Color.green.opacity(0.8)
        } else if score >= 0.7 {
            return Color.blue
        } else if score >= 0.6 {
            return Color.orange
        } else if score >= 0.5 {
            return Color.orange.opacity(0.7)
        } else {
            return .red
        }
    }
    
    // Priorité de l'action recommandée pour le tri
    var actionPriority: Int {
        switch recommendedAction {
        case "Acheter":
            return 0
        case "Renforcer":
            return 1
        case "Garder":
            return 2
        case "Vendre":
            return 3
        default:
            return 4
        }
    }
    
    // Méthode pour faciliter la comparaison et le tri
    static func sortByPriorityAndScore(_ rec1: Recommendation, _ rec2: Recommendation) -> Bool {
        if rec1.actionPriority != rec2.actionPriority {
            return rec1.actionPriority < rec2.actionPriority
        } else {
            return rec1.score > rec2.score
        }
    }
}

// Extension with enhanced mock data
extension Recommendation {
    static var usTechMock: [Recommendation] {
        [
            Recommendation(symbol: "AAPL", name: "Apple Inc.", region: "United States", sector: "Technology", score: 0.92, recommendedAction: "Acheter", allocation: 4500, sentiment: 0.85),
            Recommendation(symbol: "MSFT", name: "Microsoft Corporation", region: "United States", sector: "Technology", score: 0.90, recommendedAction: "Acheter", allocation: 4300, sentiment: 0.82),
            Recommendation(symbol: "GOOGL", name: "Alphabet Inc.", region: "United States", sector: "Communication Services", score: 0.88, recommendedAction: "Acheter", allocation: 4000, sentiment: 0.80),
            Recommendation(symbol: "AMZN", name: "Amazon.com, Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.85, recommendedAction: "Renforcer", allocation: 3800, sentiment: 0.75),
            Recommendation(symbol: "TSLA", name: "Tesla, Inc.", region: "United States", sector: "Automotive", score: 0.78, recommendedAction: "Garder", allocation: 3600, sentiment: 0.65)
        ]
    }
    
    static var diversifiedMock: [Recommendation] {
        [
            Recommendation(symbol: "AAPL", name: "Apple Inc.", region: "United States", sector: "Technology", score: 0.95, recommendedAction: "Acheter", allocation: 5000, sentiment: 0.90),
            Recommendation(symbol: "MSFT", name: "Microsoft Corporation", region: "United States", sector: "Technology", score: 0.93, recommendedAction: "Acheter", allocation: 4800, sentiment: 0.88),
            Recommendation(symbol: "GOOGL", name: "Alphabet Inc.", region: "United States", sector: "Communication Services", score: 0.91, recommendedAction: "Acheter", allocation: 4500, sentiment: 0.85),
            Recommendation(symbol: "AMZN", name: "Amazon.com Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.88, recommendedAction: "Acheter", allocation: 4300, sentiment: 0.82),
            Recommendation(symbol: "META", name: "Meta Platforms Inc.", region: "United States", sector: "Communication Services", score: 0.86, recommendedAction: "Renforcer", allocation: 3900, sentiment: 0.78),
            Recommendation(symbol: "TSLA", name: "Tesla Inc.", region: "United States", sector: "Automotive", score: 0.82, recommendedAction: "Renforcer", allocation: 3800, sentiment: 0.75),
            Recommendation(symbol: "NVDA", name: "NVIDIA Corporation", region: "United States", sector: "Technology", score: 0.89, recommendedAction: "Acheter", allocation: 3700, sentiment: 0.83),
            Recommendation(symbol: "JNJ", name: "Johnson & Johnson", region: "United States", sector: "Healthcare", score: 0.84, recommendedAction: "Renforcer", allocation: 3500, sentiment: 0.76),
            Recommendation(symbol: "PG", name: "Procter & Gamble Co.", region: "United States", sector: "Consumer Defensive", score: 0.80, recommendedAction: "Renforcer", allocation: 3200, sentiment: 0.72),
            Recommendation(symbol: "JPM", name: "JPMorgan Chase & Co.", region: "United States", sector: "Financial Services", score: 0.77, recommendedAction: "Garder", allocation: 3000, sentiment: 0.68),
            Recommendation(symbol: "V", name: "Visa Inc.", region: "United States", sector: "Financial Services", score: 0.76, recommendedAction: "Garder", allocation: 2900, sentiment: 0.65),
            Recommendation(symbol: "ASML", name: "ASML Holding NV", region: "Netherlands", sector: "Technology", score: 0.85, recommendedAction: "Renforcer", allocation: 2800, sentiment: 0.77),
            Recommendation(symbol: "LVMH", name: "LVMH Moët Hennessy Louis Vuitton", region: "France", sector: "Consumer Cyclical", score: 0.83, recommendedAction: "Renforcer", allocation: 2600, sentiment: 0.76),
            Recommendation(symbol: "SAP", name: "SAP SE", region: "Germany", sector: "Technology", score: 0.79, recommendedAction: "Garder", allocation: 2400, sentiment: 0.70),
            Recommendation(symbol: "BABA", name: "Alibaba Group Holding Ltd.", region: "China", sector: "Consumer Cyclical", score: 0.48, recommendedAction: "Vendre", allocation: 2000, sentiment: 0.22),
            Recommendation(symbol: "TCEHY", name: "Tencent Holdings Ltd.", region: "China", sector: "Communication Services", score: 0.45, recommendedAction: "Vendre", allocation: 1800, sentiment: 0.20),
            Recommendation(symbol: "9988.HK", name: "Alibaba Group Holding Ltd.", region: "Hong Kong", sector: "Consumer Cyclical", score: 0.42, recommendedAction: "Vendre", allocation: 1600, sentiment: 0.18),
            Recommendation(symbol: "0700.HK", name: "Tencent Holdings Ltd.", region: "Hong Kong", sector: "Communication Services", score: 0.38, recommendedAction: "Vendre", allocation: 1400, sentiment: 0.15),
            Recommendation(symbol: "BP", name: "BP p.l.c.", region: "United Kingdom", sector: "Energy", score: 0.35, recommendedAction: "Vendre", allocation: 1200, sentiment: 0.10),
            Recommendation(symbol: "NSRGY", name: "Nestlé S.A.", region: "Switzerland", sector: "Consumer Defensive", score: 0.32, recommendedAction: "Vendre", allocation: 1000, sentiment: 0.08),
            Recommendation(symbol: "BRK.A", name: "Berkshire Hathaway Inc.", region: "United States", sector: "Financial Services", score: 0.78, recommendedAction: "Garder", allocation: 3100, sentiment: 0.65),
            Recommendation(symbol: "UNH", name: "UnitedHealth Group Inc.", region: "United States", sector: "Healthcare", score: 0.77, recommendedAction: "Garder", allocation: 2800, sentiment: 0.68),
            Recommendation(symbol: "XOM", name: "Exxon Mobil Corporation", region: "United States", sector: "Energy", score: 0.65, recommendedAction: "Garder", allocation: 2700, sentiment: 0.45),
            Recommendation(symbol: "WMT", name: "Walmart Inc.", region: "United States", sector: "Consumer Defensive", score: 0.74, recommendedAction: "Garder", allocation: 2750, sentiment: 0.62),
            Recommendation(symbol: "MA", name: "Mastercard Inc.", region: "United States", sector: "Financial Services", score: 0.82, recommendedAction: "Renforcer", allocation: 3300, sentiment: 0.75),
            Recommendation(symbol: "HD", name: "The Home Depot, Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.75, recommendedAction: "Garder", allocation: 2850, sentiment: 0.65),
            Recommendation(symbol: "PFE", name: "Pfizer Inc.", region: "United States", sector: "Healthcare", score: 0.64, recommendedAction: "Garder", allocation: 2300, sentiment: 0.45),
            Recommendation(symbol: "AVGO", name: "Broadcom Inc.", region: "United States", sector: "Technology", score: 0.81, recommendedAction: "Renforcer", allocation: 3000, sentiment: 0.72),
            Recommendation(symbol: "KO", name: "The Coca-Cola Company", region: "United States", sector: "Consumer Defensive", score: 0.72, recommendedAction: "Garder", allocation: 2500, sentiment: 0.58),
            Recommendation(symbol: "DIS", name: "The Walt Disney Company", region: "United States", sector: "Communication Services", score: 0.73, recommendedAction: "Garder", allocation: 2750, sentiment: 0.60)
        ]
    }
}
