//
//  Article.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

struct Article: Identifiable, Codable {
    let id = UUID()
    let title: String
    let url: URL
    let publishedAt: Date
    let source: String
}

// Extension pour les données mock
extension Article {
    static let mock: [Article] = [
        .init(
            title: "Apple annonce de nouveaux résultats records",
            url: URL(string: "https://example.com/news/1")!,
            publishedAt: Date(),
            source: "Financial Times"
        ),
        .init(
            title: "Microsoft dépasse les attentes pour le quatrième trimestre",
            url: URL(string: "https://example.com/news/2")!,
            publishedAt: Date().addingTimeInterval(-86400), // -1 jour
            source: "Wall Street Journal"
        ),
        .init(
            title: "Les valeurs technologiques en hausse suite aux bons résultats",
            url: URL(string: "https://example.com/news/3")!,
            publishedAt: Date().addingTimeInterval(-172800), // -2 jours
            source: "Bloomberg"
        )
    ]
}
