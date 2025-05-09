//
//  NewsService.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum NewsError: Error { case failed }

struct NewsService {
    private static let baseURL = URL(string: "http://10.40.10.119:8000")! // IP de ton Mac
    
    static func fetchNews(for symbol: String) async throws -> [Article] {
        var components = URLComponents(url: baseURL.appendingPathComponent("news"),
                                     resolvingAgainstBaseURL: false)!
        components.queryItems = [.init(name: "symbol", value: symbol)]
        
        guard let url = components.url else { throw NewsError.failed }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NewsError.failed }
        
        return try JSONDecoder().decode([Article].self, from: data)
    }
}
