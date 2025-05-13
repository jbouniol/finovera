//
//  APIService.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum APIError: Error { 
    case invalidURL, requestFailed, decodingFailed 
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "URL invalide"
        case .requestFailed: return "Échec de la requête"
        case .decodingFailed: return "Erreur de décodage"
        }
    }
    
}

struct APIService {
    // Configuration de l'URL selon l'environnement
    #if DEBUG
    // Adresse IP de votre Mac sur le réseau local (à modifier selon votre configuration)
    // Cette adresse doit être accessible depuis votre iPhone sur le même réseau WiFi
    private static let baseURL = URL(string: "http://192.168.1.10:8000")!
    #else
    // URL d'API de production
    private static let baseURL = URL(string: "https://api.finovera.com")!
    #endif
    
    // Pour personnaliser l'URL de l'API (utile pour les tests manuels)
    static var customBaseURL: URL? = nil
    
    // URL effective à utiliser (priorité à l'URL personnalisée si définie)
    private static var effectiveBaseURL: URL {
        if let customURL = customBaseURL {
            return customURL
        }
        return baseURL
    }
    
    // Pour forcer l'utilisation de mocks en CI/CD ou tests
    private static let useMocks = ProcessInfo.processInfo.environment["CI"] != nil
    
    // Pour permettre l'accès à l'URL de base en mode debug (utile pour l'affichage)
    #if DEBUG
    static var baseURLForDebug: URL {
        return baseURL
    }
    #endif

    static func fetchRecommendations(risk: String,
                                     regions: [String],
                                     sectors: [String],
                                     capital: Double) async throws -> [Recommendation] {
        // En environnement CI, retourner des données mockées
        if useMocks {
            return Recommendation.mock
        }

        var components = URLComponents(url: effectiveBaseURL.appendingPathComponent("recommendations"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "risk", value: risk),
            .init(name: "capital", value: String(Int(capital * 100))) // Conversion en entier représentant le pourcentage
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

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Recommendation].self, from: data)
    }
    
    static func fetchNews(for symbol: String) async throws -> [Article] {
        // En environnement CI, retourner des données mockées
        if useMocks {
            return Article.mock
        }
        
        var components = URLComponents(url: effectiveBaseURL.appendingPathComponent("news"),
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
        // En environnement CI, ne rien faire
        if useMocks {
            return
        }
        
        var req = URLRequest(url: effectiveBaseURL.appendingPathComponent("add_ticker"))
        req.httpMethod = "POST"
        req.httpBody   = try JSONEncoder().encode(["symbol": symbol])
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[API] POST", req.url?.absoluteString ?? "nil") // Log de l'URL complète
        
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
    }
    
    static func fetchAvailableMetadata() async throws -> (regions: [String], sectors: [String]) {
        // En environnement CI, retourner des données mockées
        if useMocks {
            return (
                ["United States", "Europe", "Asia", "China", "Japan"],
                ["Technology", "Healthcare", "Consumer Cyclical", "Financial Services"]
            )
        }
        
        let url = effectiveBaseURL.appendingPathComponent("available_metadata")
        
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
}
