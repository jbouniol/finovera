//
//  PortfolioView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

@MainActor
final class PortfolioViewModel: ObservableObject {
    @Published var portfolio: [Recommendation] = []
    @Published var isLoading = false
    @Published var showMockAlert = false
    @Published var error: Error?
    
    func loadPortfolio() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Essai de charger depuis l'API
                portfolio = try await loadPortfolioFromAPI()
            } catch {
                self.error = error
                print("Erreur API Portfolio: \(error.localizedDescription)")
                
                // Utilisation du mock en cas d'erreur
                portfolio = Recommendation.mockPortfolio
                showMockAlert = true
            }
        }
    }
    
    private func loadPortfolioFromAPI() async throws -> [Recommendation] {
        // Ici on pourrait avoir une vraie API mais pour l'exemple on utilise toujours le mock
        // et on simule un délai réseau
        try await Task.sleep(for: .seconds(1))
        
        // Pour tester, on peut décommenter cette ligne pour simuler une erreur
        // throw NSError(domain: "PortfolioError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API indisponible"])
        
        return Recommendation.mockPortfolio
    }
}

struct PortfolioView: View {
    @StateObject private var vm = PortfolioViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Valeur totale du portefeuille
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Value")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("$\(totalValue, specifier: "%.2f")")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Actions du portefeuille
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Holdings")
                            .font(.title2)
                            .bold()
                        
                        if vm.portfolio.isEmpty && !vm.isLoading {
                            Text("No stocks in your portfolio yet.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(vm.portfolio) { stock in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stock.symbol)
                                            .font(.headline)
                                        Text(stock.name)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("$\(stock.allocation, specifier: "%.2f")")
                                            .font(.headline)
                                        Text("\(percentOfTotal(stock: stock), specifier: "%.1f")%")
                                            .font(.subheadline)
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
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.loadPortfolio()
            }
            .overlay {
                if vm.isLoading {
                    LoadingView(message: "Loading your portfolio...")
                }
            }
            .alert("Using Demo Data", isPresented: $vm.showMockAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The portfolio is currently displaying mock data with Apple stock as an example.")
            }
        }
    }
    
    // Calculer la valeur totale du portefeuille
    private var totalValue: Double {
        vm.portfolio.reduce(0) { $0 + $1.allocation }
    }
    
    // Calculer le pourcentage de chaque action dans le portefeuille
    private func percentOfTotal(stock: Recommendation) -> Double {
        guard totalValue > 0 else { return 0 }
        return (stock.allocation / totalValue) * 100
    }
}

#Preview {
    PortfolioView()
} 