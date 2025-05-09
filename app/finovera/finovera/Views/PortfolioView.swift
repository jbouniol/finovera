//
//  PortfolioView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI
import Charts

@MainActor
final class PortfolioViewModel: ObservableObject {
    @Published var portfolio: [Recommendation] = []
    @Published var news: [Article] = []
    @Published var isLoading = false
    @Published var showMockAlert = false
    @Published var userTickers: String = ""
    @Published var selectedRisk: String = "balanced"
    @Published var selectedRegions: [String] = ["US"]
    @Published var selectedSectors: [String] = ["Technology"]
    
    // Chargement du portefeuille
    func loadPortfolio() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Récupère les tickers ajoutés par l'utilisateur
                let tickers = userTickers
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                if tickers.isEmpty {
                    // S'il n'y a pas de tickers, on charge les recommandations générales
                    portfolio = try await APIService.fetchRecommendations(
                        risk: selectedRisk,
                        regions: selectedRegions,
                        sectors: selectedSectors,
                        capital: 10000
                    )
                } else {
                    // Sinon, on charge les informations spécifiques pour ces tickers
                    // Dans un monde idéal, on appellerait une API pour ça
                    portfolio = Recommendation.mockPortfolio
                    showMockAlert = true
                }
                
                // Charger les nouvelles pour le premier ticker
                if let firstTicker = portfolio.first {
                    loadNews(for: firstTicker.symbol)
                }
            } catch {
                print("Erreur chargement portfolio: \(error.localizedDescription)")
                portfolio = Recommendation.mockPortfolio
                showMockAlert = true
            }
        }
    }
    
    // Chargement des news
    func loadNews(for symbol: String) {
        Task {
            do {
                news = try await APIService.fetchNews(for: symbol)
            } catch {
                print("Erreur chargement news: \(error.localizedDescription)")
                news = []
            }
        }
    }
}

struct PortfolioView: View {
    @StateObject private var vm = PortfolioViewModel()
    @State private var showRiskPicker = false
    @State private var showRegionPicker = false
    @State private var showSectorPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section filtres
                    filterSection
                    
                    // Section portefeuille utilisateur
                    portfolioInputSection
                    
                    // Section recommandations
                    if !vm.portfolio.isEmpty {
                        recommendationsSection
                    }
                    
                    // Section actualités
                    if !vm.news.isEmpty {
                        newsSection
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.loadPortfolio()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                vm.loadPortfolio()
            }
            .overlay {
                if vm.isLoading {
                    LoadingView(message: "Analyse de votre portefeuille...")
                }
            }
            .alert("Mode démo", isPresented: $vm.showMockAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Les données du portefeuille sont simulées pour l'exemple.")
            }
            .sheet(isPresented: $showRiskPicker) {
                riskPickerSheet
            }
            .sheet(isPresented: $showRegionPicker) {
                regionPickerSheet
            }
            .sheet(isPresented: $showSectorPicker) {
                sectorPickerSheet
            }
        }
    }
    
    // Filtres (Risque, Région, Secteur)
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filtres d'investissement")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        vm.selectedRisk = "balanced"
                        vm.selectedRegions = ["US"]
                        vm.selectedSectors = ["Technology"]
                        vm.loadPortfolio()
                    }
                } label: {
                    Label("Réinitialiser", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    showRiskPicker = true
                } label: {
                    HStack {
                        Image(systemName: "gauge.medium")
                        Text("Risque")
                        Spacer()
                        Text(vm.selectedRisk.capitalized)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut, value: vm.selectedRisk)
                
                Button {
                    showRegionPicker = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Régions")
                        Spacer()
                        if vm.selectedRegions.count <= 2 {
                            Text(vm.selectedRegions.joined(separator: ", "))
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(vm.selectedRegions.count) sélectionnées")
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut, value: vm.selectedRegions)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button {
                        showSectorPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                            Text("Secteurs")
                            Spacer()
                            if vm.selectedSectors.count <= 2 {
                                Text(vm.selectedSectors.joined(separator: ", "))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(vm.selectedSectors.count) sélectionnés")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color("CardBG"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut, value: vm.selectedSectors)
                }
                // Chips pour secteurs sélectionnés
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.selectedSectors, id: \.self) { sector in
                            HStack(spacing: 4) {
                                Text(sector)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color("Accent").opacity(0.15))
                                    .clipShape(Capsule())
                                Button {
                                    withAnimation {
                                        vm.selectedSectors.removeAll { $0 == sector }
                                        vm.loadPortfolio()
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }
    
    // Saisie du portefeuille utilisateur
    private var portfolioInputSection: some View {
        VStack(spacing: 12) {
            Text("Votre portefeuille")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Saisissez vos tickers séparés par des virgules")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Ex: AAPL, MSFT, GOOGL", text: $vm.userTickers)
                    .padding()
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    vm.loadPortfolio()
                } label: {
                    Text("Analyser mon portefeuille")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    // Liste des recommandations
    private var recommendationsSection: some View {
        VStack(spacing: 12) {
            Text("Recommandations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(vm.portfolio) { rec in
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rec.symbol)
                                .font(.headline)
                            Text(rec.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Text("Score: ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(rec.score * 100))")
                                    .font(.headline)
                            }
                            
                            Text(rec.recommendedAction)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    rec.recommendedAction == "Renforcer" ? Color.green.opacity(0.2) :
                                    rec.recommendedAction == "Garder" ? Color.yellow.opacity(0.2) :
                                    Color.red.opacity(0.2)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.loadNews(for: rec.symbol)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secteur")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(rec.sector)
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("Sentiment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(rec.sentimentLabel)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    rec.sentimentLabel.contains("positif") ? Color.green.opacity(0.2) :
                                    rec.sentimentLabel == "Neutre" ? Color.gray.opacity(0.2) :
                                    Color.red.opacity(0.2)
                                )
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Région")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(rec.region)
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color("CardBG"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // Section actualités
    private var newsSection: some View {
        VStack(spacing: 12) {
            Text("Actualités récentes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(vm.news.prefix(5)) { article in
                Link(destination: article.url) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(article.source)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(article.publishedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // Feuille de sélection du risque
    private var riskPickerSheet: some View {
        VStack(spacing: 20) {
            Text("Sélectionnez votre profil de risque")
                .font(.headline)
                .padding()
            
            ForEach(["conservative", "balanced", "aggressive"], id: \.self) { risk in
                Button {
                    vm.selectedRisk = risk
                    showRiskPicker = false
                    vm.loadPortfolio()
                } label: {
                    HStack {
                        Text(risk.capitalized)
                            .foregroundColor(.primary)
                        Spacer()
                        if vm.selectedRisk == risk {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Accent"))
                        }
                    }
                    .padding()
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
    
    // Feuille de sélection des régions
    private var regionPickerSheet: some View {
        VStack(spacing: 20) {
            Text("Sélectionnez les régions")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(["US", "Europe", "Asia", "Global"], id: \.self) { region in
                        Button {
                            if vm.selectedRegions.contains(region) {
                                vm.selectedRegions.removeAll { $0 == region }
                            } else {
                                vm.selectedRegions.append(region)
                            }
                        } label: {
                            HStack {
                                Text(region)
                                    .foregroundColor(.primary)
                                Spacer()
                                if vm.selectedRegions.contains(region) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("Accent"))
                                }
                            }
                            .padding()
                            .background(Color("CardBG"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button {
                showRegionPicker = false
                vm.loadPortfolio()
            } label: {
                Text("Appliquer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
    
    // Feuille de sélection des secteurs
    private var sectorPickerSheet: some View {
        VStack(spacing: 20) {
            Text("Sélectionnez les secteurs")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(["Technology", "Healthcare", "Finance", "Energy", "Consumer", "Industrial"], id: \.self) { sector in
                        Button {
                            if vm.selectedSectors.contains(sector) {
                                vm.selectedSectors.removeAll { $0 == sector }
                            } else {
                                vm.selectedSectors.append(sector)
                            }
                        } label: {
                            HStack {
                                Text(sector)
                                    .foregroundColor(.primary)
                                Spacer()
                                if vm.selectedSectors.contains(sector) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("Accent"))
                                }
                            }
                            .padding()
                            .background(Color("CardBG"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button {
                showSectorPicker = false
                vm.loadPortfolio()
            } label: {
                Text("Appliquer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Accent"))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    PortfolioView()
} 