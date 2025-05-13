//
//  Sector.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum Sector: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    
    case technology = "Technology"
    case healthcare = "Healthcare" 
    case consumerCyclical = "Consumer Cyclical"
    case financialServices = "Financial Services"
    case communication = "Communication Services"
    case consumerDefensive = "Consumer Defensive"
    case industrials = "Industrials"
    case basicMaterials = "Basic Materials"
    case energy = "Energy"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case etf = "ETF"
}
