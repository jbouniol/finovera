//
//  RecommendationDetailVM.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

@MainActor
class RecommendationDetailVM: ObservableObject {
    @Published var news: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    func loadNews(for symbol: String) {
        isLoading = true
        
        Task {
            do {
                news = try await APIService.fetchNews(for: symbol)
            } catch {
                errorMessage = "Could not load news: \(error.localizedDescription)"
                showError = true
                print("Error loading news: \(error)")
                
                // Fallback to mock data if error and not already using mocks
                if !APIService.useMocks {
                    news = Article.getMockNews(for: symbol)
                }
            }
            
            isLoading = false
        }
    }
}
