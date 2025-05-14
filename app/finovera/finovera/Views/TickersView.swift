//
//  TickersView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct TickersView: View {
    @StateObject private var viewModel = TickersViewModel()
    @State private var showAddTickerSheet = false
    @State private var showFiltersSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter chips
                filterChips
                
                // Tickers list
                tickersList
            }
            .background(Color("Background"))
            .navigationTitle("Tickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTickerSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFiltersSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            let count = viewModel.selectedRegions.count + viewModel.selectedSectors.count
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTickerSheet) {
                addTickerSheet
            }
            .sheet(isPresented: $showFiltersSheet) {
                filtersSheet
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "Chargement des tickers...")
                }
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
    
    // Search bar component
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search tickers", text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) {
                        viewModel.applyFilters()
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.applyFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color("CardBG"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // Filter chips showing active filters
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Show active filters
                ForEach(Array(viewModel.selectedSectors), id: \.self) { sector in
                    filterChip(title: sector, icon: "tag") {
                        viewModel.toggleSector(sector)
                    }
                }
                
                ForEach(Array(viewModel.selectedRegions), id: \.self) { region in
                    filterChip(title: region, icon: "globe") {
                        viewModel.toggleRegion(region)
                    }
                }
                
                // Reset button if filters are active
                if !viewModel.selectedSectors.isEmpty || !viewModel.selectedRegions.isEmpty {
                    Button {
                        viewModel.resetFilters()
                    } label: {
                        Text("Reset")
                            .font(.caption)
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .opacity(viewModel.selectedSectors.isEmpty && viewModel.selectedRegions.isEmpty ? 0 : 1)
        .frame(height: viewModel.selectedSectors.isEmpty && viewModel.selectedRegions.isEmpty ? 0 : nil)
    }
    
    // Individual filter chip
    private func filterChip(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .padding(6)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
        }
    }
    
    // Tickers list with sections
    private var tickersList: some View {
        List {
            if viewModel.filteredTickers.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.groupedTickers, id: \.0) { (letter, tickers) in
                    Section(header: Text(letter)) {
                        ForEach(tickers) { ticker in
                            tickerRow(ticker)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // Empty state when no tickers match filters
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            if !viewModel.searchText.isEmpty || !viewModel.selectedSectors.isEmpty || !viewModel.selectedRegions.isEmpty {
                Text("No tickers match your filters")
                    .font(.headline)
                
                Button {
                    viewModel.resetFilters()
                } label: {
                    Text("Reset Filters")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            } else {
                Text("No tickers found")
                    .font(.headline)
                
                Button {
                    showAddTickerSheet = true
                } label: {
                    Text("Add Ticker")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
    
    // Individual ticker row
    private func tickerRow(_ ticker: TickerMetadata) -> some View {
        NavigationLink(destination: RecommendationDetailView(symbol: ticker.ticker)) {
            HStack(spacing: 12) {
                Text(ticker.ticker)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ticker.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(ticker.sector, systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(ticker.region, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // Add ticker sheet
    private var addTickerSheet: some View {
        AddTickerView { symbol in
            Task {
                let success = await viewModel.addTicker(symbol)
                if success {
                    showAddTickerSheet = false
                }
            }
        }
    }
    
    // Filters sheet
    private var filtersSheet: some View {
        NavigationStack {
            List {
                // Sectors section
                Section(header: Text("Sectors")) {
                    ForEach(viewModel.availableSectors, id: \.self) { sector in
                        Button {
                            viewModel.toggleSector(sector)
                        } label: {
                            HStack {
                                Text(sector)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedSectors.contains(sector) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                // Regions section
                Section(header: Text("Regions")) {
                    ForEach(viewModel.availableRegions, id: \.self) { region in
                        Button {
                            viewModel.toggleRegion(region)
                        } label: {
                            HStack {
                                Text(region)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedRegions.contains(region) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showFiltersSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                    .foregroundColor(viewModel.selectedRegions.isEmpty && viewModel.selectedSectors.isEmpty ? .secondary : .red)
                    .disabled(viewModel.selectedRegions.isEmpty && viewModel.selectedSectors.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TickersView()
}
