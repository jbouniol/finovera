//
//  RecommendationDetailView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI
import Charts

struct RecommendationDetailView: View {
    @StateObject private var viewModel = RecommendationDetailVM()
    @Environment(\.dismiss) private var dismiss
    
    // View can be initialized either with a recommendation or a symbol
    private var recommendation: Recommendation?
    private var symbol: String
    
    // Initializer with a recommendation
    init(ticker: Recommendation) {
        self.recommendation = ticker
        self.symbol = ticker.symbol
    }
    
    // Initializer with just a symbol (for direct ticker viewing)
    init(symbol: String) {
        self.recommendation = nil
        self.symbol = symbol
    }
    
    // Backward compatibility
    init(rec: Recommendation) {
        self.recommendation = rec
        self.symbol = rec.symbol
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with ticker and name
                headerSection
                
                // If we have a recommendation, show the score and allocation
                if let recommendation = recommendation {
                    recommendationSection(recommendation)
                }
                
                // News section
                newsSection
            }
            .padding()
        }
        .background(Color("Background"))
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadNews(for: symbol)
        }
    }
    
    // Header with ticker info
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(symbol)
                        .font(.title)
                        .bold()
                    
                    if let recommendation = recommendation {
                        Text(recommendation.name)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Show sector and region if available
                if let recommendation = recommendation {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(recommendation.sector, systemImage: "tag")
                            .font(.caption)
                        
                        Label(recommendation.region, systemImage: "globe")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // Recommendation section with score and allocation
    private func recommendationSection(_ recommendation: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendation")
                .font(.headline)
            
            HStack(spacing: 30) {
                // Score
                VStack {
                    ZStack {
                        Circle()
                            .stroke(
                                Color.gray.opacity(0.2),
                                lineWidth: 10
                            )
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(recommendation.score))
                            .stroke(
                                scoreColor(for: recommendation.score),
                                style: StrokeStyle(
                                    lineWidth: 10,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(recommendation.score * 100))")
                            .font(.system(.title, design: .rounded))
                            .bold()
                    }
                    .frame(width: 80, height: 80)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Action
                VStack {
                    Text(recommendation.recommendedAction)
                        .font(.title2)
                        .bold()
                        .foregroundColor(actionColor(for: recommendation.recommendedAction))
                    
                    Text("Action")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Allocation
                VStack {
                    Text("$\(Int(recommendation.allocation))")
                        .font(.title2)
                        .bold()
                    
                    Text("Allocation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .padding()
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // News section
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent News")
                .font(.headline)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if viewModel.news.isEmpty {
                Text("No recent news found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.news) { article in
                    Button {
                        UIApplication.shared.open(article.url)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(article.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Text(article.source)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatDate(article.publishedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color("CardBG").opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // Helper functions
    private func scoreColor(for score: Double) -> Color {
        if score >= 0.7 {
            return .green
        } else if score >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func actionColor(for action: String) -> Color {
        switch action {
        case "Renforcer": return .green
        case "Garder": return .orange
        case "Vendre": return .red
        default: return .primary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
