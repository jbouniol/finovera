//
//  APIService.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum APIError: Error {
    case invalidURL, requestFailed, decodingFailed, noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "URL invalide"
        case .requestFailed: return "Échec de la requête"
        case .decodingFailed: return "Erreur de décodage"
        case .noData: return "Aucune donnée reçue"
        }
    }
}

class APIService {
    // MARK: - Properties
    
    // Base URLs
    static let baseURLForRelease = URL(string: "https://finovera-api.vercel.app/api")!
    static let baseURLForDebug = URL(string: "http://localhost:5000/api")!
    
    // Static properties
    static var customBaseURL: URL?
    static var useMockDataOverride: Bool = false
    
    // Computed properties
    static var baseURL: URL {
        if let customURL = customBaseURL, !customURL.absoluteString.isEmpty {
            return customURL
        }
        
        #if DEBUG
        return baseURLForDebug
        #else
        return baseURLForRelease
        #endif
    }
    
    // Check if running in CI environment (GitHub Actions)
    static var useMocks: Bool {
        return ProcessInfo.processInfo.environment["CI"] == "true" || useMockDataOverride
    }
    
    // Pour permettre l'accès à l'URL de base en mode debug (utile pour l'affichage)

    // MARK: - API Methods
    
    static func fetchRecommendations(regions: [String], sectors: [String], allocationAmount: Double) async throws -> [Recommendation] {
        if useMocks {
            // Utiliser le mock mis à jour par défaut qui inclut plus d'actions
            let defaultMock = Recommendation.updatedMock
            
            // Sélectionner le mock adapté en fonction des régions et secteurs
            if regions.contains("United States") && sectors.contains("Financial Services") && sectors.count == 1 {
                return Recommendation.financialSectorMock
            } else if regions.contains("United States") && 
                      (sectors.contains("Technology") || sectors.contains("Communication Services")) && 
                      regions.count == 1 && sectors.count <= 2 {
                return Recommendation.usTechMock
            } else if (regions.contains("France") || regions.contains("Germany") || regions.contains("United Kingdom") || 
                       regions.contains("Netherlands") || regions.contains("Switzerland") || regions.contains("Denmark") || 
                       regions.contains("Italy") || regions.contains("Spain")) && regions.count >= 1 {
                return Recommendation.europeanMock
            } else if (regions.contains("China") || regions.contains("Japan") || regions.contains("South Korea") ||
                       regions.contains("Taiwan") || regions.contains("Hong Kong")) && regions.count >= 1 {
                return Recommendation.asianMock
            } else if regions.count >= 3 || sectors.count >= 3 {
                return Recommendation.diversifiedMock
            } else {
                return defaultMock
            }
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("recommendations"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "risk", value: "high"),
            .init(name: "capital", value: String(Int(allocationAmount * 100))) // Conversion en entier représentant le pourcentage
        ]
        if !regions.isEmpty {
            components.queryItems?.append(.init(name: "regions", value: regions.joined(separator: ",")))
        }
        if !sectors.isEmpty {
            components.queryItems?.append(.init(name: "sectors", value: sectors.joined(separator: ",")))
        }

        guard let url = components.url else { throw APIError.invalidURL }
        
        print("[API] GET", url.absoluteString) // Log de l'URL complète

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        
        guard !data.isEmpty else { throw APIError.noData }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Recommendation].self, from: data)
    }
    
    static func fetchNews(for symbol: String) async throws -> [Article] {
        if useMocks {
            return Article.getMockNews(for: symbol)
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("news"),
                                     resolvingAgainstBaseURL: false)!
        components.queryItems = [.init(name: "symbol", value: symbol)]
        
        guard let url = components.url else { throw APIError.invalidURL }
        
        print("[API] GET", url.absoluteString) // Log de l'URL complète
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Article].self, from: data)
    }
    
    static func addTicker(_ symbol: String) async throws {
        if useMocks {
            // Just simulate a delay for the mock
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            return
        }
        
        var req = URLRequest(url: baseURL.appendingPathComponent("add_ticker"))
        req.httpMethod = "POST"
        req.httpBody   = try JSONEncoder().encode(["symbol": symbol])
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[API] POST", req.url?.absoluteString ?? "nil") // Log de l'URL complète
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        
        // Retourner le message de confirmation si disponible
        if !data.isEmpty {
            let decoder = JSONDecoder()
            struct AddTickerResponse: Codable {
                let message: String
            }
            let responseData = try? decoder.decode(AddTickerResponse.self, from: data)
            print("[API] Ticker ajouté: \(responseData?.message ?? "Succès")")
        }
    }
    
    static func fetchAvailableMetadata() async throws -> (regions: [String], sectors: [String]) {
        if useMocks {
            return (
                regions: ["United States", "China", "Japan", "United Kingdom", "France", "Germany", "Canada", "Switzerland", "Netherlands", "Hong Kong", "Australia", "India", "Brazil", "South Korea"],
                sectors: ["Technology", "Financial Services", "Healthcare", "Consumer Cyclical", "Communication Services", "Industrials", "Consumer Defensive", "Energy", "Basic Materials", "Real Estate", "Utilities", "Automotive"]
            )
        }
        
        let url = baseURL.appendingPathComponent("available_metadata")
        
        print("[API] GET", url.absoluteString) // Log de l'URL complète
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        
        struct MetadataResponse: Codable {
            let regions: [String]
            let sectors: [String]
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let metadataResponse = try decoder.decode(MetadataResponse.self, from: data)
        
        return (metadataResponse.regions, metadataResponse.sectors)
    }
    
    static func fetchTickersMetadata() async throws -> [TickerMetadata] {
        if useMocks {
            return [
                TickerMetadata(ticker: "AAPL", name: "Apple Inc.", country: "United States", sector: "Technology"),
                TickerMetadata(ticker: "MSFT", name: "Microsoft Corporation", country: "United States", sector: "Technology"),
                TickerMetadata(ticker: "GOOGL", name: "Alphabet Inc.", country: "United States", sector: "Communication Services"),
                TickerMetadata(ticker: "AMZN", name: "Amazon.com, Inc.", country: "United States", sector: "Consumer Cyclical"),
                TickerMetadata(ticker: "META", name: "Meta Platforms, Inc.", country: "United States", sector: "Communication Services"),
                TickerMetadata(ticker: "TSLA", name: "Tesla Inc.", country: "United States", sector: "Automotive"),
                TickerMetadata(ticker: "NVDA", name: "NVIDIA Corporation", country: "United States", sector: "Technology"),
                TickerMetadata(ticker: "JNJ", name: "Johnson & Johnson", country: "United States", sector: "Healthcare"),
                TickerMetadata(ticker: "PG", name: "Procter & Gamble Co.", country: "United States", sector: "Consumer Defensive"),
                TickerMetadata(ticker: "JPM", name: "JPMorgan Chase & Co.", country: "United States", sector: "Financial Services"),
                TickerMetadata(ticker: "V", name: "Visa Inc.", country: "United States", sector: "Financial Services"),
                TickerMetadata(ticker: "ASML", name: "ASML Holding NV", country: "Netherlands", sector: "Technology"),
                TickerMetadata(ticker: "LVMH", name: "LVMH Moët Hennessy Louis Vuitton", country: "France", sector: "Consumer Cyclical"),
                TickerMetadata(ticker: "SAP", name: "SAP SE", country: "Germany", sector: "Technology"),
                TickerMetadata(ticker: "BABA", name: "Alibaba Group Holding Ltd.", country: "China", sector: "Consumer Cyclical"),
                TickerMetadata(ticker: "TCEHY", name: "Tencent Holdings Ltd.", country: "China", sector: "Communication Services"),
                TickerMetadata(ticker: "9988.HK", name: "Alibaba Group Holding Ltd.", country: "Hong Kong", sector: "Consumer Cyclical"),
                TickerMetadata(ticker: "0700.HK", name: "Tencent Holdings Ltd.", country: "Hong Kong", sector: "Communication Services"),
                TickerMetadata(ticker: "BP", name: "BP p.l.c.", country: "United Kingdom", sector: "Energy"),
                TickerMetadata(ticker: "NSRGY", name: "Nestlé S.A.", country: "Switzerland", sector: "Consumer Defensive")
            ]
        }
        
        let url = baseURL.appendingPathComponent("tickers_metadata")
        
        print("[API] GET", url.absoluteString)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
        
        let decoder = JSONDecoder()
        return try decoder.decode([TickerMetadata].self, from: data)
    }
}
