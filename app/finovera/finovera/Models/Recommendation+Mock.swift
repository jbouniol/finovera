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
        .init(symbol: "AAPL", name: "Apple Inc.",   score: 88, reason: "Haute profitabilité et momentum positif."),
        .init(symbol: "MSFT", name: "Microsoft",    score: 85, reason: "Croissance Azure soutenue."),
        .init(symbol: "NVDA", name: "NVIDIA Corp.", score: 82, reason: "Leader GPU, méga-tendance IA."),
        .init(symbol: "AIR",  name: "Airbus SE",    score: 78, reason: "Carnet de commandes record.")
    ]
}
