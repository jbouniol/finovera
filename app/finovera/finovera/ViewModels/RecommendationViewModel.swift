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
    @Published var addedTickers: [TickerMetadata] = []
    @Published var showTickerSuccessMessage = false
    @Published var successMessage: String? = nil
    
    private var hasShownOfflineAlert = false
    
    // Détection de l'environnement CI/tests
    private let isCI = ProcessInfo.processInfo.environment["CI"] != nil
    private let isUITesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    // -------------- Persisted choices --------------
    @AppStorage("capitalTarget")  var capitalTarget: Double = 10000
    @AppStorage("regions")        private var regionsRaw: String = ""
    @AppStorage("sectors")        private var sectorsRaw: String = ""
    @AppStorage("userTickers")    private var userTickersRaw: String = ""

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
    
    // User tickers
    var userTickers: [String] {
        get { userTickersRaw.split(separator: ",").map { String($0) } }
        set { userTickersRaw = newValue.joined(separator: ",") }
    }

    // -------------- Networking --------------
    func load() {
        Task {
            await loadAddedTickers()
            await loadRecommendations()
        }
    }
    
    func loadAddedTickers() async {
        do {
            let allTickers = try await APIService.fetchTickersMetadata()
            // Filter to only include user added tickers
            if !userTickers.isEmpty {
                addedTickers = allTickers.filter { userTickers.contains($0.ticker) }
            } else {
                addedTickers = []
            }
        } catch {
            print("Error loading added tickers: \(error.localizedDescription)")
            addedTickers = []
        }
    }

    func loadRecommendations() async {
        // Si nous sommes en CI ou tests UI, utiliser directement les mocks
        if isCI || isUITesting {
            recs = Recommendation.mock
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        do {
            let activeRegions = regions.map { $0.name }
            let activeSectors = sectors.map { $0.rawValue }
            
            // Use the API service to fetch recommendations
            recs = try await APIService.fetchRecommendations(
                regions: activeRegions,
                sectors: activeSectors,
                allocationAmount: capitalTarget
            )
            
            // Sort recommendations by score
            recs.sort { $0.score > $1.score }
            
            // Reset offline mode if successful
            offlineMessage = nil
            showOfflineAlert = false
            hasShownOfflineAlert = false
        } catch {
            print("Error loading recommendations: \(error)")
            
            // Show offline mode alert - only if we're not already in mock/offline mode
            if !APIService.useMocks {
                offlineMessage = "Impossible de charger les recommandations : \(error.localizedDescription)"
                showOfflineAlert = true
                hasShownOfflineAlert = true
            }
        }
    }
    
    // Add a ticker to user's watchlist
    func addTicker(_ symbol: String) async -> Bool {
        guard !symbol.isEmpty else { return false }
        
        isLoading = true
        
        do {
            try await APIService.addTicker(symbol)
            
            // Reload data
            await loadAddedTickers()
            await loadRecommendations()
            
            // Show success message
            successMessage = "Le ticker \(symbol) a été ajouté avec succès."
            showTickerSuccessMessage = true
            
            // Hide message after delay
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                withAnimation {
                    showTickerSuccessMessage = false
                }
            }
            
            isLoading = false
            return true
        } catch {
            print("Error adding ticker: \(error)")
            isLoading = false
            return false
        }
    }
    
    // Remove a ticker from user's watchlist
    func removeTicker(_ symbol: String) {
        if userTickers.contains(symbol) {
            userTickers = userTickers.filter { $0 != symbol }
            
            // Reload data
            Task {
                await loadAddedTickers()
                await loadRecommendations()
            }
        }
    }

    // -------------- Mutators --------------
    func updateCapitalTarget(_ value: Double) {
        capitalTarget = value
        Task {
            await loadRecommendations()
        }
    }
    func toggleRegion(_ r: InvestmentRegion) {
        regions.toggle(r)
        Task {
            await loadRecommendations()
        }
    }
    func toggleSector(_ s: Sector) {
        sectors.toggle(s)
        Task {
            await loadRecommendations()
        }
    }
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

