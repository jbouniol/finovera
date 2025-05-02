//
//  NewsService.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum NewsError: Error { case failed }

struct NewsService {
    static func fetchNews(for symbol: String) async throws -> [Article] {
        // — MOCK —
        try await Task.sleep(for: .seconds(0.4))
        let sample = [
            Article(title: "\(symbol) beats Q1 earnings estimates, shares jump",
                    url: URL(string: "https://example.com/\(symbol)/earnings")!,
                    publishedAt: .now, source: "Example News"),
            Article(title: "\(symbol) launches new AI product line",
                    url: URL(string: "https://example.com/\(symbol)/ai")!,
                    publishedAt: .now.addingTimeInterval(-86400),
                    source: "Daily Tech")
        ]
        return sample
    }
}
