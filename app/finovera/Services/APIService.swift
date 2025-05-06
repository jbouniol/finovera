import Foundation

class APIService {
    // Remplacer par l'IP de votre Mac sur le réseau local
    private let baseURL = "http://172.16.29.129:8000"  // À modifier avec votre IP
    
    func fetchRecommendations(risk: String, capital: Double) async throws -> [Recommendation] {
        let urlString = "\(baseURL)/recommendations?risk=\(risk)&capital=\(capital)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Recommendation].self, from: data)
    }
    
    func fetchNews(for symbol: String) async throws -> [Article] {
        let urlString = "\(baseURL)/news?symbol=\(symbol)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Article].self, from: data)
    }
    
    func addTicker(_ symbol: String) async throws -> Bool {
        let urlString = "\(baseURL)/add_ticker"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["symbol": symbol]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TickerResponse.self, from: data)
        return response.success
    }
}

// Modèles de données
struct Recommendation: Codable {
    let symbol: String
    let name: String
    let score: Double
    let allocation: Double
    let sector: String
    let region: String
}

struct Article: Codable {
    let title: String
    let url: String
    let publishedAt: Date
    let source: String
}

struct TickerResponse: Codable {
    let success: Bool
    let message: String
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
} 