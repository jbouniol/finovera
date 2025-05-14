//
//  HomeView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUICore
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = RecommendationViewModel()
    @AppStorage("onboardingDone") private var onboardingDone = false
    @AppStorage("useMockData") private var useMockData: Bool = false
    @State private var showStylePicker = false
    @State private var showRegionPicker = false
    @State private var showSectorPicker = false
    @State private var showAddTickerSheet = false
    @State private var showAllRecos = false
    @State private var ticker = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Fond
                Color("Background").ignoresSafeArea()
                
                // Contenu principal
                ScrollView {
                    VStack(spacing: 24) {
                        // Espacement pour compenser le logo
                        Spacer().frame(height: 100)
                        
                        // Quick Add Ticker
                        quickAddTickerSection
                        
                        // Recently Added Tickers
                        if !viewModel.addedTickers.isEmpty {
                            recentTickersSection
                        }
                        
                        // Top Recommendations Preview
                        topRecommendationsSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                
                // Logo fixe en haut
                VStack {
                    LogoHeader()
                        .scaleEffect(1.2)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color("Background")
                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                        )
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "Chargement des recommandations...")
                }
                
                if viewModel.showTickerSuccessMessage, let message = viewModel.successMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .padding()
                            .background(Color.green.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.showTickerSuccessMessage)
                }
            }
            .sheet(isPresented: $showAddTickerSheet) {
                AddTickerView { symbol in
                    Task {
                        let success = await viewModel.addTicker(symbol)
                        if success {
                            showAddTickerSheet = false
                        }
                    }
                }
            }
            .alert(viewModel.offlineMessage ?? "Mode hors-ligne", isPresented: $viewModel.showOfflineAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                viewModel.load()
            }
            .refreshable {
                await viewModel.loadRecommendations()
                await viewModel.loadAddedTickers()
            }
        }
    }
    
    // Quick ticker add section
    private var quickAddTickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ajouter un Ticker")
                .font(.headline)
                .foregroundColor(Color("Accent"))
            
            HStack {
                TextField("Symbole (ex: AAPL, MSFT, GOOGL)", text: $ticker)
                    .textInputAutocapitalization(.characters)
                    .padding(12)
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                Button {
                    if !ticker.isEmpty {
                        Task {
                            let success = await viewModel.addTicker(ticker)
                            if success {
                                ticker = ""
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("Accent"))
                        .padding(6)
                }
                .disabled(ticker.isEmpty)
                .buttonStyle(.plain)
                .background(Circle().fill(Color("CardBG")))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            Button {
                showAddTickerSheet = true
            } label: {
                Text("Options avancées")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color("CardBG").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // Recent tickers section
    private var recentTickersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vos Tickers")
                    .font(.headline)
                    .foregroundColor(Color("Accent"))
                
                Spacer()
                
                NavigationLink(destination: TickersView()) {
                    Text("Voir tous")
                        .font(.caption)
                        .foregroundColor(Color("Accent"))
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.addedTickers.prefix(5)) { ticker in
                        NavigationLink(destination: RecommendationDetailView(symbol: ticker.ticker)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(ticker.ticker)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.primary)
                                
                                Text(ticker.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Label(ticker.sector, systemImage: "tag")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(16)
                            .frame(width: 170, height: 110)
                            .background(Color("CardBG"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color("CardBG").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // Top recommendations section
    private var topRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommandations")
                    .font(.headline)
                    .foregroundColor(Color("Accent"))
                
                Spacer()
                
                NavigationLink(destination: PortfolioView()) {
                    Text("Voir toutes")
                        .font(.caption)
                        .foregroundColor(Color("Accent"))
                }
            }
            
            if viewModel.recs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Chargement des recommandations...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    // Utiliser la nouvelle méthode de tri
                    ForEach(viewModel.recs.sorted(by: Recommendation.sortByPriorityAndScore).prefix(5)) { rec in
                        NavigationLink(destination: RecommendationDetailView(ticker: rec)) {
                            RecommendationCard(recommendation: rec)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("CardBG").opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color("CardBG").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
}
