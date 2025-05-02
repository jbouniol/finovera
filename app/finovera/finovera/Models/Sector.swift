//
//  Sector.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation

enum Sector: String, CaseIterable, Identifiable, Codable {
    case energy = "Energy"
    case banks = "Banks"
    case esg = "ESG"
    case bigData = "Big Data"
    case technology = "Technology"

    var id: String { rawValue }
}
