//
//  InvestmentRegion.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

enum InvestmentRegion: String, CaseIterable, Identifiable, Codable {
    case us, canada, france, germany, italy, uk, japan, europe, world, asia

    var id: String { rawValue }

    var title: String {
        switch self {
        case .us:      "United States"
        case .canada:  "Canada"
        case .france:  "France"
        case .germany: "Germany"
        case .italy:   "Italy"
        case .uk:      "United Kingdom"
        case .japan:   "Japan"
        case .europe:  "Europe"
        case .world:   "World"
        case .asia:    "Asia-Pacific"
        }
    }

    /// Flag emoji (fallback) – ou place des images SF si dispo
    var flag: String {
        switch self {
        case .us:      "🇺🇸"
        case .canada:  "🇨🇦"
        case .france:  "🇫🇷"
        case .germany: "🇩🇪"
        case .italy:   "🇮🇹"
        case .uk:      "🇬🇧"
        case .japan:   "🇯🇵"
        case .europe:  "🇪🇺"
        case .world:   "🌐"
        case .asia:    "🌏"
        }
    }
}
