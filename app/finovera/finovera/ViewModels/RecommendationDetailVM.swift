//
//  RecommendationDetailVM.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

@MainActor
final class RecommendationDetailVM: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false

    func loadNews(symbol: String) {
        Task {
            isLoading = true
            articles = (try? await NewsService.fetchNews(for: symbol)) ?? []
            isLoading = false
        }
    }
}
