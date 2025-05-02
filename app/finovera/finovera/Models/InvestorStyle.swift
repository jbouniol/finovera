//
//  InvestorStyle.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

enum InvestorStyle: String, CaseIterable, Identifiable, Codable {
    case conservative, balanced, aggressive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conservative: "Conservative"
        case .balanced:     "Moderate"
        case .aggressive:   "Aggressive"
        }
    }

    var subtitle: String {
        switch self {
        case .conservative: "I want to preserve 90% of my capital"
        case .balanced:     "I want to preserve 80% of my capital"
        case .aggressive:   "I want to preserve 70% of my capital"
        }
    }

    var preservation: Int {
        switch self {
        case .conservative: 90
        case .balanced:     80
        case .aggressive:   70
        }
    }

    /// simple waveform SF Symbol variation to mimic capture
    var icon: String {
        switch self {
        case .conservative: "waveform.path.ecg"
        case .balanced:     "waveform"
        case .aggressive:   "waveform.path.ecg.rectangle"
        }
    }

    /// RGB (purple) when selected - adapt if needed
    static let selectedColor = Color(red: 72/255, green: 43/255, blue: 205/255)
}
