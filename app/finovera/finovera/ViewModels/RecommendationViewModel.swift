//
//  RecommendationViewModel.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

@MainActor
final class RecommendationViewModel: ObservableObject {

    // -------------- UI State --------------
    @Published var recs: [Recommendation] = []
    @Published var isLoading = false          // ➜ popup de chargement
    @Published var showOfflineAlert = false

    // -------------- Persisted choices --------------
    @AppStorage("capitalTarget")  var capitalTarget: Double = 80      // %
    @AppStorage("regions")        private var regionsRaw: String = ""
    @AppStorage("sectors")        private var sectorsRaw: String = ""

    // risk devient DÉRIVÉ du capitalTarget
    var risk: InvestorStyle {
        let adjusted = 100 - capitalTarget       // tu peux multiplier ici
        switch adjusted {
        case 15...:      return .aggressive
        case 10..<15:    return .balanced
        default:         return .conservative
        }
    }


    // region / sector helpers identiques
    var regions: Set<InvestmentRegion> {
        get { Set(regionsRaw.split(separator: ",").compactMap { InvestmentRegion(rawValue: String($0)) }) }
        set { regionsRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }
    var sectors: Set<Sector> {
        get { Set(sectorsRaw.split(separator: ",").compactMap { Sector(rawValue: String($0)) }) }
        set { sectorsRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }

    // -------------- Networking --------------
    func load() {
        Task {
            withAnimation { isLoading = true }
            defer { withAnimation { isLoading = false } }

            do {
                recs = try await APIService.fetchRecommendations(
                    risk: risk.rawValue,
                    regions: regions.map(\.rawValue),
                    sectors: sectors.map(\.rawValue),
                    capital: capitalTarget
                )
            } catch {
                recs = Recommendation.mock
                showOfflineAlert = true
            }
        }
    }

    // -------------- Mutators --------------
    func updateCapitalTarget(_ value: Double) { capitalTarget = value ; load() }
    func toggleRegion(_ r: InvestmentRegion)  { regions.toggle(r);   load() }
    func toggleSector(_ s: Sector)            { sectors.toggle(s);  load() }
    func updateCapitalTarget(_ value: Double, completion: @escaping () -> Void) {
        capitalTarget = value
        Task {
            await load()
            completion()
        }
    }


}

extension Set {
    /// Inverse la présence d’un élément dans le Set
    mutating func toggle(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}

