//
//  InvestmentRegion.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI
import Foundation

enum InvestmentRegion: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    
    var name: String { rawValue }
    
    // Pays majeurs
    case unitedStates = "United States"
    case china = "China"
    case japan = "Japan"
    case unitedKingdom = "United Kingdom"
    case germany = "Germany"
    case france = "France"
    case canada = "Canada"
    case australia = "Australia"
    case switzerland = "Switzerland"
    case brazil = "Brazil"
    case india = "India"
    case mexico = "Mexico"
    case ireland = "Ireland"
    case finland = "Finland"
    case uruguay = "Uruguay"
    
    // Régions génériques
    case europe = "Europe"
    case asia = "Asia"
    case latinAmerica = "Latin America"
    case africa = "Africa"
    case middleEast = "Middle East"
    case other = "Other"
    
    // Fallback pour ETF
    case us = "US"
    
    var flagEmoji: String {
        switch self {
        case .unitedStates: return "🇺🇸"
        case .china: return "🇨🇳"
        case .japan: return "🇯🇵"
        case .unitedKingdom: return "🇬🇧"
        case .germany: return "🇩🇪"
        case .france: return "🇫🇷"
        case .canada: return "🇨🇦"
        case .australia: return "🇦🇺"
        case .switzerland: return "🇨🇭"
        case .brazil: return "🇧🇷"
        case .india: return "🇮🇳"
        case .mexico: return "🇲🇽"
        case .ireland: return "🇮🇪"
        case .finland: return "🇫🇮"
        case .uruguay: return "🇺🇾"
        case .europe: return "🇪🇺"
        case .asia: return "🌏"
        case .latinAmerica: return "🌎"
        case .africa: return "🌍"
        case .middleEast: return "🌍"
        case .us: return "🇺🇸"
        case .other: return "🌐"
        }
    }
    
    var flag: String { flagEmoji }
}
