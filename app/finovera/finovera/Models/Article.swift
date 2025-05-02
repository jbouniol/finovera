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
