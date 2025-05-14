//
//  TickersViewModel.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import Foundation
import SwiftUI

@MainActor
class TickersViewModel: ObservableObject {
    @Published var tickers: [TickerMetadata] = []
    @Published var filteredTickers: [TickerMetadata] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    // Filters
    @Published var selectedSectors: Set<String> = []
    @Published var selectedRegions: Set<String> = []
    
    // Available metadata for filters
    @Published var availableSectors: [String] = []
    @Published var availableRegions: [String] = []
    
    // Grouped tickers for section list
    var groupedTickers: [(String, [TickerMetadata])] {
        let grouped = Dictionary(grouping: filteredTickers) { ticker in
            ticker.firstLetter
        }

        return grouped
            .map { (key: String, value: [TickerMetadata]) in (key, value) }
            .sorted { $0.0 < $1.0 }
    }
    
    // Apply filters and search
    func applyFilters() {
        filteredTickers = tickers.filter { ticker in
            let matchesSearch = searchText.isEmpty || 
                ticker.ticker.localizedCaseInsensitiveContains(searchText) ||
                ticker.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesSector = selectedSectors.isEmpty || selectedSectors.contains(ticker.sector)
            let matchesRegion = selectedRegions.isEmpty || selectedRegions.contains(ticker.country)
            
            return matchesSearch && matchesSector && matchesRegion
        }
    }
    
    // Loads all tickers and available metadata
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get tickers metadata
            tickers = try await APIService.fetchTickersMetadata()
            
            // Get available metadata for filters
            let metadata = try await APIService.fetchAvailableMetadata()
            availableRegions = metadata.regions
            availableSectors = metadata.sectors
            
            // Apply filters
            applyFilters()
        } catch {
            errorMessage = "Failed to load tickers: \(error.localizedDescription)"
            showError = true
            print("Error loading tickers: \(error)")
        }
        
        isLoading = false
    }
    
    // Add a new ticker
    func addTicker(_ symbol: String) async -> Bool {
        guard !symbol.isEmpty else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await APIService.addTicker(symbol.uppercased())
            
            // Reload data to include the new ticker
            await loadData()
            return true
        } catch {
            errorMessage = "Failed to add ticker: \(error.localizedDescription)"
            showError = true
            print("Error adding ticker: \(error)")
            isLoading = false
            return false
        }
    }
    
    // Toggle sector selection
    func toggleSector(_ sector: String) {
        if selectedSectors.contains(sector) {
            selectedSectors.remove(sector)
        } else {
            selectedSectors.insert(sector)
        }
        applyFilters()
    }
    
    // Toggle region selection
    func toggleRegion(_ region: String) {
        if selectedRegions.contains(region) {
            selectedRegions.remove(region)
        } else {
            selectedRegions.insert(region)
        }
        applyFilters()
    }
    
    // Reset all filters
    func resetFilters() {
        selectedSectors.removeAll()
        selectedRegions.removeAll()
        searchText = ""
        applyFilters()
    }
} 
