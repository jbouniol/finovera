//
//  RecommendationDetailView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct RecommendationDetailView: View {
    let rec: Recommendation
    @StateObject private var vm = RecommendationDetailVM()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Divider()

                Text("Latest news")
                    .font(.headline)
                if vm.isLoading {
                    ProgressView()
                } else if vm.articles.isEmpty {
                    Text("No recent news.").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.articles) { article in
                        ArticleRow(article: article)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(rec.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.loadNews(symbol: rec.symbol) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rec.name).font(.title2).bold()
            Text("Relevance score \(Int(rec.score))/100")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(rec.reason).font(.body)
        }
    }
}

private struct ArticleRow: View {
    let article: Article
    var body: some View {
        Link(destination: article.url) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title).fontWeight(.semibold)
                HStack {
                    Text(article.source).font(.caption)
                    Spacer()
                    Text(article.publishedAt, style: .date).font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}
