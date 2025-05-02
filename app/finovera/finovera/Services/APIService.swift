//
//  APIService.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum APIError: Error { case invalidURL, requestFailed, decodingFailed }

struct APIService {
    private static let baseURL = URL(string: "http://127.0.0.1:8000")!   // change si déployé

    static func fetchRecommendations(risk: String,
                                     regions: [String],
                                     sectors: [String],
                                     capital: Double) async throws -> [Recommendation] {

        var components = URLComponents(url: baseURL.appendingPathComponent("recommendations"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "risk", value: risk),
            .init(name: "capital", value: String(Int(capital)))
        ]
        if !regions.isEmpty {
            components.queryItems?.append(.init(name: "regions", value: regions.joined(separator: ",")))
        }
        if !sectors.isEmpty {
            components.queryItems?.append(.init(name: "sectors", value: sectors.joined(separator: ",")))
        }

        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw APIError.requestFailed }

        return try JSONDecoder().decode([Recommendation].self, from: data)
    }
    
    static func addTicker(_ symbol: String) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("add_ticker"))
        req.httpMethod = "POST"
        req.httpBody   = try JSONEncoder().encode(["symbol": symbol])
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await URLSession.shared.data(for: req)
    }


}
