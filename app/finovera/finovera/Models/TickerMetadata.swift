//
//  TickerMetadata.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

struct TickerMetadata: Identifiable, Codable, Hashable {
    var id: String { ticker }
    let ticker: String
    let name: String
    let country: String
    let sector: String
    
    // Computed property for displaying the region in a more user-friendly format
    var region: String {
        return country
    }
    
    // Used for displaying in lists with section headers
    var firstLetter: String {
        return String(ticker.prefix(1))
    }
    
    static var examples: [TickerMetadata] {
        [
            .init(ticker: "AAPL", name: "Apple Inc.", country: "United States", sector: "Technology"),
            .init(ticker: "MSFT", name: "Microsoft Corporation", country: "United States", sector: "Technology"),
            .init(ticker: "GOOGL", name: "Alphabet Inc.", country: "United States", sector: "Communication Services"),
            .init(ticker: "AMZN", name: "Amazon.com, Inc.", country: "United States", sector: "Consumer Cyclical"),
            .init(ticker: "META", name: "Meta Platforms, Inc.", country: "United States", sector: "Communication Services")
        ]
    }
} 