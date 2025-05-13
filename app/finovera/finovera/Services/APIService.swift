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
    private static let baseURL = URL(string: "http://10.40.10.119:8000")! // Localhost pour le développement

    static func fetchRecommendations(risk: String,
                                     regions: [String],
                                     sectors: [String],
                                     capital: Double) async throws -> [Recommendation] {

        var components = URLComponents(url: baseURL.appendingPathComponent("recommendations"),
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
        var req = URLRequest(url: baseURL.appendingPathComponent("add_ticker"))
        req.httpMethod = "POST"
        req.httpBody   = try JSONEncoder().encode(["symbol": symbol])
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[API] POST", req.url?.absoluteString ?? "nil") // Log de l'URL complète
        
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }
    }
    
    static func fetchAvailableMetadata() async throws -> (regions: [String], sectors: [String]) {
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
}
