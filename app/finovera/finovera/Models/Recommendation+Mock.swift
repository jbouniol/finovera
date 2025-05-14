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
        .init(symbol: "AAPL", name: "Apple Inc.", region: "United States", sector: "Technology", score: 0.92, recommendedAction: "Acheter", allocation: 2000, sentiment: 0.85),
        .init(symbol: "MSFT", name: "Microsoft", region: "United States", sector: "Technology", score: 0.90, recommendedAction: "Acheter", allocation: 1800, sentiment: 0.82),
        .init(symbol: "NVDA", name: "NVIDIA Corp.", region: "United States", sector: "Technology", score: 0.88, recommendedAction: "Acheter", allocation: 1700, sentiment: 0.80),
        .init(symbol: "GOOGL", name: "Alphabet Inc.", region: "United States", sector: "Communication Services", score: 0.85, recommendedAction: "Renforcer", allocation: 1400, sentiment: 0.75),
        .init(symbol: "AMZN", name: "Amazon.com Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.82, recommendedAction: "Renforcer", allocation: 1300, sentiment: 0.70),
        .init(symbol: "AIR.PA", name: "Airbus SE", region: "Europe", sector: "Industrials", score: 0.78, recommendedAction: "Garder", allocation: 1200, sentiment: 0.55),
        .init(symbol: "TSLA", name: "Tesla Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.74, recommendedAction: "Garder", allocation: 1100, sentiment: 0.48),
        .init(symbol: "JNJ", name: "Johnson & Johnson", region: "United States", sector: "Healthcare", score: 0.71, recommendedAction: "Garder", allocation: 1000, sentiment: 0.37),
        .init(symbol: "V", name: "Visa Inc.", region: "United States", sector: "Financial Services", score: 0.70, recommendedAction: "Garder", allocation: 950, sentiment: 0.42),
        .init(symbol: "JPM", name: "JPMorgan Chase & Co.", region: "United States", sector: "Financial Services", score: 0.68, recommendedAction: "Garder", allocation: 900, sentiment: 0.30),
        .init(symbol: "META", name: "Meta Platforms Inc.", region: "United States", sector: "Communication Services", score: 0.75, recommendedAction: "Garder", allocation: 1250, sentiment: 0.58),
        .init(symbol: "ASML", name: "ASML Holding NV", region: "Netherlands", sector: "Technology", score: 0.83, recommendedAction: "Renforcer", allocation: 1600, sentiment: 0.65),
        .init(symbol: "LVMH.PA", name: "LVMH Moët Hennessy", region: "France", sector: "Consumer Cyclical", score: 0.76, recommendedAction: "Garder", allocation: 1150, sentiment: 0.52),
        .init(symbol: "BRK-A", name: "Berkshire Hathaway", region: "United States", sector: "Financial Services", score: 0.73, recommendedAction: "Garder", allocation: 1050, sentiment: 0.45),
        .init(symbol: "TM", name: "Toyota Motor Corp.", region: "Japan", sector: "Automotive", score: 0.69, recommendedAction: "Garder", allocation: 980, sentiment: 0.40),
        .init(symbol: "9988.HK", name: "Alibaba Group", region: "China", sector: "Consumer Cyclical", score: 0.54, recommendedAction: "Vendre", allocation: 700, sentiment: 0.25),
        .init(symbol: "TCEHY", name: "Tencent Holdings", region: "China", sector: "Communication Services", score: 0.56, recommendedAction: "Vendre", allocation: 750, sentiment: 0.28),
        .init(symbol: "BP", name: "BP p.l.c.", region: "United Kingdom", sector: "Energy", score: 0.60, recommendedAction: "Vendre", allocation: 800, sentiment: 0.32),
        .init(symbol: "HSBC", name: "HSBC Holdings", region: "United Kingdom", sector: "Financial Services", score: 0.62, recommendedAction: "Vendre", allocation: 850, sentiment: 0.35),
        .init(symbol: "7203.T", name: "Toyota Motor Corp.", region: "Japan", sector: "Automotive", score: 0.69, recommendedAction: "Garder", allocation: 980, sentiment: 0.40),
        .init(symbol: "SONY", name: "Sony Group Corp.", region: "Japan", sector: "Technology", score: 0.72, recommendedAction: "Garder", allocation: 1050, sentiment: 0.43),
        .init(symbol: "NSRGY", name: "Nestlé S.A.", region: "Switzerland", sector: "Consumer Defensive", score: 0.67, recommendedAction: "Garder", allocation: 920, sentiment: 0.39),
        .init(symbol: "RY", name: "Royal Bank of Canada", region: "Canada", sector: "Financial Services", score: 0.65, recommendedAction: "Garder", allocation: 880, sentiment: 0.37),
        .init(symbol: "SAP", name: "SAP SE", region: "Germany", sector: "Technology", score: 0.71, recommendedAction: "Garder", allocation: 1000, sentiment: 0.44),
        // Actions européennes supplémentaires
        .init(symbol: "BNP.PA", name: "BNP Paribas", region: "France", sector: "Financial Services", score: 0.69, recommendedAction: "Garder", allocation: 950, sentiment: 0.42),
        .init(symbol: "SAN.PA", name: "Sanofi", region: "France", sector: "Healthcare", score: 0.72, recommendedAction: "Garder", allocation: 1050, sentiment: 0.47),
        .init(symbol: "ORA.PA", name: "Orange", region: "France", sector: "Communication Services", score: 0.64, recommendedAction: "Garder", allocation: 850, sentiment: 0.38),
        .init(symbol: "ENI.MI", name: "Eni SpA", region: "Italy", sector: "Energy", score: 0.62, recommendedAction: "Garder", allocation: 820, sentiment: 0.36),
        .init(symbol: "ENEL.MI", name: "Enel SpA", region: "Italy", sector: "Utilities", score: 0.68, recommendedAction: "Garder", allocation: 900, sentiment: 0.41),
        .init(symbol: "ISP.MI", name: "Intesa Sanpaolo", region: "Italy", sector: "Financial Services", score: 0.65, recommendedAction: "Garder", allocation: 870, sentiment: 0.39),
        .init(symbol: "SIE.DE", name: "Siemens AG", region: "Germany", sector: "Industrials", score: 0.75, recommendedAction: "Garder", allocation: 1100, sentiment: 0.53),
        .init(symbol: "VOW3.DE", name: "Volkswagen AG", region: "Germany", sector: "Automotive", score: 0.67, recommendedAction: "Garder", allocation: 900, sentiment: 0.40),
        .init(symbol: "ALV.DE", name: "Allianz SE", region: "Germany", sector: "Financial Services", score: 0.71, recommendedAction: "Garder", allocation: 1000, sentiment: 0.48),
        .init(symbol: "ADS.DE", name: "Adidas AG", region: "Germany", sector: "Consumer Cyclical", score: 0.73, recommendedAction: "Garder", allocation: 1050, sentiment: 0.49),
        .init(symbol: "SAN.MC", name: "Banco Santander", region: "Spain", sector: "Financial Services", score: 0.63, recommendedAction: "Garder", allocation: 830, sentiment: 0.37),
        .init(symbol: "IBE.MC", name: "Iberdrola SA", region: "Spain", sector: "Utilities", score: 0.69, recommendedAction: "Garder", allocation: 950, sentiment: 0.43),
        .init(symbol: "TEF.MC", name: "Telefónica", region: "Spain", sector: "Communication Services", score: 0.61, recommendedAction: "Garder", allocation: 810, sentiment: 0.35),
        .init(symbol: "UNA.AS", name: "Unilever NV", region: "Netherlands", sector: "Consumer Defensive", score: 0.76, recommendedAction: "Garder", allocation: 1150, sentiment: 0.52),
        .init(symbol: "PHIA.AS", name: "Koninklijke Philips", region: "Netherlands", sector: "Healthcare", score: 0.70, recommendedAction: "Garder", allocation: 970, sentiment: 0.45),
        .init(symbol: "AZN.L", name: "AstraZeneca PLC", region: "United Kingdom", sector: "Healthcare", score: 0.80, recommendedAction: "Renforcer", allocation: 1400, sentiment: 0.62),
        .init(symbol: "GSK.L", name: "GlaxoSmithKline", region: "United Kingdom", sector: "Healthcare", score: 0.73, recommendedAction: "Garder", allocation: 1050, sentiment: 0.51),
        .init(symbol: "ULVR.L", name: "Unilever PLC", region: "United Kingdom", sector: "Consumer Defensive", score: 0.75, recommendedAction: "Garder", allocation: 1100, sentiment: 0.54),
        .init(symbol: "RIO.L", name: "Rio Tinto Group", region: "United Kingdom", sector: "Basic Materials", score: 0.65, recommendedAction: "Garder", allocation: 880, sentiment: 0.38),
        .init(symbol: "ABBN.SW", name: "ABB Ltd", region: "Switzerland", sector: "Industrials", score: 0.72, recommendedAction: "Garder", allocation: 1020, sentiment: 0.47),
        .init(symbol: "NOVN.SW", name: "Novartis AG", region: "Switzerland", sector: "Healthcare", score: 0.78, recommendedAction: "Garder", allocation: 1250, sentiment: 0.57),
        .init(symbol: "UHR.SW", name: "The Swatch Group", region: "Switzerland", sector: "Consumer Cyclical", score: 0.71, recommendedAction: "Garder", allocation: 1000, sentiment: 0.46),
        .init(symbol: "DANSKE.CO", name: "Danske Bank", region: "Denmark", sector: "Financial Services", score: 0.62, recommendedAction: "Garder", allocation: 820, sentiment: 0.37),
        .init(symbol: "NOVO-B.CO", name: "Novo Nordisk A/S", region: "Denmark", sector: "Healthcare", score: 0.85, recommendedAction: "Renforcer", allocation: 1700, sentiment: 0.67)
    ]
    
    // Mock spécifique pour le portefeuille
    static let mockPortfolio: [Recommendation] = [
        .init(symbol: "AAPL", name: "Apple Inc.", region: "United States", sector: "Technology", score: 0.92, recommendedAction: "Acheter", allocation: 2000, sentiment: 0.85),
        .init(symbol: "MSFT", name: "Microsoft", region: "United States", sector: "Technology", score: 0.90, recommendedAction: "Acheter", allocation: 1800, sentiment: 0.82),
        .init(symbol: "NVDA", name: "NVIDIA Corp.", region: "United States", sector: "Technology", score: 0.88, recommendedAction: "Acheter", allocation: 1700, sentiment: 0.80),
        .init(symbol: "TSLA", name: "Tesla Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.74, recommendedAction: "Garder", allocation: 1100, sentiment: 0.48),
        .init(symbol: "AMZN", name: "Amazon.com Inc.", region: "United States", sector: "Consumer Cyclical", score: 0.82, recommendedAction: "Renforcer", allocation: 1300, sentiment: 0.70)
    ]
    
    // Secteur financier
    static let financialSectorMock: [Recommendation] = [
        .init(symbol: "JPM", name: "JPMorgan Chase & Co.", region: "United States", sector: "Financial Services", score: 0.89, recommendedAction: "Acheter", allocation: 3800, sentiment: 0.75),
        .init(symbol: "BAC", name: "Bank of America Corp.", region: "United States", sector: "Financial Services", score: 0.85, recommendedAction: "Acheter", allocation: 3600, sentiment: 0.72),
        .init(symbol: "WFC", name: "Wells Fargo & Co.", region: "United States", sector: "Financial Services", score: 0.78, recommendedAction: "Renforcer", allocation: 3300, sentiment: 0.65),
        .init(symbol: "C", name: "Citigroup Inc.", region: "United States", sector: "Financial Services", score: 0.73, recommendedAction: "Renforcer", allocation: 3100, sentiment: 0.60),
        .init(symbol: "GS", name: "Goldman Sachs Group", region: "United States", sector: "Financial Services", score: 0.82, recommendedAction: "Renforcer", allocation: 3500, sentiment: 0.68),
        .init(symbol: "MS", name: "Morgan Stanley", region: "United States", sector: "Financial Services", score: 0.80, recommendedAction: "Renforcer", allocation: 3400, sentiment: 0.65),
        .init(symbol: "BLK", name: "BlackRock Inc.", region: "United States", sector: "Financial Services", score: 0.85, recommendedAction: "Acheter", allocation: 3800, sentiment: 0.73),
        .init(symbol: "AXP", name: "American Express Co.", region: "United States", sector: "Financial Services", score: 0.79, recommendedAction: "Renforcer", allocation: 3600, sentiment: 0.65)
    ]

    // Portefeuille européen
    static let europeanMock: [Recommendation] = [
        .init(symbol: "ASML", name: "ASML Holding NV", region: "Netherlands", sector: "Technology", score: 0.83, recommendedAction: "Renforcer", allocation: 4400, sentiment: 0.65),
        .init(symbol: "LVMH.PA", name: "LVMH Moët Hennessy Louis Vuitton", region: "France", sector: "Consumer Cyclical", score: 0.81, recommendedAction: "Renforcer", allocation: 4200, sentiment: 0.63),
        .init(symbol: "SAP", name: "SAP SE", region: "Germany", sector: "Technology", score: 0.78, recommendedAction: "Garder", allocation: 3900, sentiment: 0.59),
        .init(symbol: "SIE.DE", name: "Siemens AG", region: "Germany", sector: "Industrials", score: 0.75, recommendedAction: "Garder", allocation: 3700, sentiment: 0.53),
        .init(symbol: "NOVN.SW", name: "Novartis AG", region: "Switzerland", sector: "Healthcare", score: 0.78, recommendedAction: "Garder", allocation: 3900, sentiment: 0.57),
        .init(symbol: "NOVO-B.CO", name: "Novo Nordisk A/S", region: "Denmark", sector: "Healthcare", score: 0.85, recommendedAction: "Renforcer", allocation: 4500, sentiment: 0.67),
        .init(symbol: "AZN.L", name: "AstraZeneca PLC", region: "United Kingdom", sector: "Healthcare", score: 0.80, recommendedAction: "Renforcer", allocation: 4100, sentiment: 0.62),
        .init(symbol: "SAN.PA", name: "Sanofi", region: "France", sector: "Healthcare", score: 0.72, recommendedAction: "Garder", allocation: 3500, sentiment: 0.47),
        .init(symbol: "ULVR.L", name: "Unilever PLC", region: "United Kingdom", sector: "Consumer Defensive", score: 0.75, recommendedAction: "Garder", allocation: 3700, sentiment: 0.54),
        .init(symbol: "UNA.AS", name: "Unilever NV", region: "Netherlands", sector: "Consumer Defensive", score: 0.76, recommendedAction: "Garder", allocation: 3800, sentiment: 0.52)
    ]

    // Actions asiatiques
    static let asianMock: [Recommendation] = [
        .init(symbol: "9988.HK", name: "Alibaba Group Holding", region: "China", sector: "Consumer Cyclical", score: 0.68, recommendedAction: "Garder", allocation: 3300, sentiment: 0.42),
        .init(symbol: "0700.HK", name: "Tencent Holdings", region: "China", sector: "Communication Services", score: 0.71, recommendedAction: "Garder", allocation: 3500, sentiment: 0.45),
        .init(symbol: "3690.HK", name: "Meituan", region: "China", sector: "Consumer Cyclical", score: 0.64, recommendedAction: "Garder", allocation: 3100, sentiment: 0.38),
        .init(symbol: "9618.HK", name: "JD.com Inc", region: "China", sector: "Consumer Cyclical", score: 0.61, recommendedAction: "Garder", allocation: 2900, sentiment: 0.36),
        .init(symbol: "1211.HK", name: "BYD Company", region: "China", sector: "Automotive", score: 0.73, recommendedAction: "Garder", allocation: 3600, sentiment: 0.48),
        .init(symbol: "6098.T", name: "Recruit Holdings", region: "Japan", sector: "Industrials", score: 0.67, recommendedAction: "Garder", allocation: 3200, sentiment: 0.43),
        .init(symbol: "6758.T", name: "Sony Group Corp", region: "Japan", sector: "Consumer Cyclical", score: 0.78, recommendedAction: "Garder", allocation: 3900, sentiment: 0.57),
        .init(symbol: "7974.T", name: "Nintendo Co Ltd", region: "Japan", sector: "Communication Services", score: 0.76, recommendedAction: "Garder", allocation: 3700, sentiment: 0.54),
        .init(symbol: "7267.T", name: "Honda Motor Co", region: "Japan", sector: "Automotive", score: 0.65, recommendedAction: "Garder", allocation: 3100, sentiment: 0.40),
        .init(symbol: "005930.KS", name: "Samsung Electronics", region: "South Korea", sector: "Technology", score: 0.80, recommendedAction: "Renforcer", allocation: 4000, sentiment: 0.59)
    ]


    // Ajouter d'autres mauvaises actions à vendre au mock principal
    static let additionalSellStocks: [Recommendation] = [
        .init(symbol: "GME", name: "GameStop Corp", region: "United States", sector: "Consumer Cyclical", score: 0.30, recommendedAction: "Vendre", allocation: 800, sentiment: 0.15),
        .init(symbol: "SNAP", name: "Snap Inc", region: "United States", sector: "Communication Services", score: 0.36, recommendedAction: "Vendre", allocation: 1000, sentiment: 0.20)
    ]

    // Mise à jour du mock principal pour inclure plus d'actions asiatiques et à vendre
    static var updatedMock: [Recommendation] {
        var result = mock
        result.append(contentsOf: [
            .init(symbol: "6758.T", name: "Sony Group Corp", region: "Japan", sector: "Consumer Cyclical", score: 0.78, recommendedAction: "Garder", allocation: 1150, sentiment: 0.57),
            .init(symbol: "005930.KS", name: "Samsung Electronics", region: "South Korea", sector: "Technology", score: 0.80, recommendedAction: "Renforcer", allocation: 1250, sentiment: 0.59),
            .init(symbol: "2330.TW", name: "Taiwan Semiconductor", region: "Taiwan", sector: "Technology", score: 0.82, recommendedAction: "Renforcer", allocation: 1300, sentiment: 0.61),
            .init(symbol: "1299.HK", name: "AIA Group", region: "Hong Kong", sector: "Financial Services", score: 0.74, recommendedAction: "Garder", allocation: 1100, sentiment: 0.52),
            .init(symbol: "9201.T", name: "Japan Airlines", region: "Japan", sector: "Industrials", score: 0.66, recommendedAction: "Garder", allocation: 950, sentiment: 0.41)
        ])
        result.append(contentsOf: additionalSellStocks)
        return result
    }
}
