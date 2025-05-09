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
    @Published var offlineMessage: String? = nil
    private var hasShownOfflineAlert = false

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
    func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }
        do {
            recs = try await APIService.fetchRecommendations(
                risk: risk.rawValue,
                regions: regions.map(\.rawValue),
                sectors: sectors.map(\.rawValue),
                capital: capitalTarget
            )
            hasShownOfflineAlert = false // reset si succès
        } catch {
            print("Erreur API: \(error.localizedDescription)")
            recs = Recommendation.mock
            if !hasShownOfflineAlert {
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    offlineMessage = "Mode hors-ligne : aucune connexion réseau détectée. Les recommandations affichées sont simulées."
                } else {
                    offlineMessage = "Mode hors-ligne : impossible de joindre le serveur. Les recommandations affichées sont simulées."
                }
                showOfflineAlert = true
                hasShownOfflineAlert = true
            }
        }
    }

    // -------------- Mutators --------------
    func updateCapitalTarget(_ value: Double) { capitalTarget = value ; loadRecommendations() }
    func toggleRegion(_ r: InvestmentRegion)  { regions.toggle(r);   loadRecommendations() }
    func toggleSector(_ s: Sector)            { sectors.toggle(s);  loadRecommendations() }
    func updateCapitalTarget(_ value: Double, completion: @escaping () -> Void) {
        capitalTarget = value
        Task {
            await loadRecommendations()
            completion()
        }
    }


}

extension Set {
    /// Inverse la présence d'un élément dans le Set
    mutating func toggle(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}

