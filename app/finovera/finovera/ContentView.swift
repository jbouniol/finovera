//
//  ContentView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    
    init() {
        // ⚙️ Look Trade Republic : barres noires, label blanc
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(Color("Background"))

        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
            
            TickersView()
                .tabItem {
                    Label("Tickers", systemImage: "list.bullet")
                }
            
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
                
            Button {
                showSettings = true
            } label: {
                Text("Paramètres")
            }
            .tabItem {
                Label("Paramètres", systemImage: "gear")
            }
        }
        .tint(Color("Accent"))           // accent vert-turquoise
        .background(Color("Background"))
        .preferredColorScheme(.dark)     // force dark (Trade Republic)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// Définition temporaire de SettingsView, à déplacer dans un fichier séparé
struct SettingsView: View {
    @AppStorage("apiBaseURL") private var apiBaseURL: String = ""
    @AppStorage("useMockData") private var useMockData: Bool = false
    @State private var tempAPIURL: String = ""
    @State private var showSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    // Variable pour désactiver l'affichage du mode démo dans les paramètres
    // Mettre à true pour les présentations
    private let hideDemoIndicator = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration API")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL du serveur")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Adresse API", text: $tempAPIURL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        tempAPIURL = ""
                        saveSettings()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Réinitialiser")
                        }
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                    }
                }
                
                // Section de mode démo pour les démonstrations
                Section(header: Text("Mode Démonstration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Utiliser les données simulées", isOn: $useMockData)
                            .tint(Color("Accent"))
                            .onChange(of: useMockData) { oldValue, newValue in
                                APIService.useMockDataOverride = newValue
                            }
                        
                        if useMockData {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Les données affichées sont simulées pour la démonstration")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("État de la connexion")) {
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL actuelle:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(APIService.customBaseURL?.absoluteString ?? APIService.baseURL.absoluteString)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(6)
                    }
                    #endif
                    
                    Button(action: {
                        testAPIConnection()
                    }) {
                        HStack {
                            Image(systemName: "network")
                            Text("Tester la connexion")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("Accent"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Informations")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image("FinoveraLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                            Spacer()
                            Text("Finovera v1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("© 2025 Jonathan Bouniol")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Paramètres")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveSettings()
                        showSaveConfirmation = true
                        
                        // Fermer automatiquement après sauvegarde
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            }
            .overlay {
                if showSaveConfirmation {
                    SaveConfirmationView()
                }
            }
            .onAppear {
                tempAPIURL = apiBaseURL
                APIService.useMockDataOverride = useMockData
            }
        }
    }
    
    private func saveSettings() {
        apiBaseURL = tempAPIURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Mettre à jour la configuration de l'API immédiatement
        if !apiBaseURL.isEmpty, let url = URL(string: apiBaseURL) {
            APIService.customBaseURL = url
        } else {
            APIService.customBaseURL = nil
        }
        
        withAnimation {
            showSaveConfirmation = true
        }
    }
    
    private func testAPIConnection() {
        Task {
            do {
                // Try to fetch available metadata as a simple connectivity test
                let _ = try await APIService.fetchAvailableMetadata()
                
                // Show success alert
                let alertController = UIAlertController(
                    title: "Connection Successful",
                    message: "Successfully connected to the API server.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = scene.windows.first?.rootViewController {
                    rootVC.present(alertController, animated: true)
                }
            } catch {
                // Show error alert
                let alertController = UIAlertController(
                    title: "Connection Failed",
                    message: "Could not connect to the API server: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = scene.windows.first?.rootViewController {
                    rootVC.present(alertController, animated: true)
                }
            }
        }
    }
}

// Animation de confirmation de sauvegarde
struct SaveConfirmationView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Paramètres enregistrés")
                .padding()
                .background(Color("Accent").opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 50)
        }
    }
}
