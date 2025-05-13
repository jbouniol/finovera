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
    @State private var tempAPIURL: String = ""
    @State private var showSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration API")) {
                    TextField("URL du serveur API", text: $tempAPIURL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Button("Réinitialiser aux valeurs par défaut") {
                        tempAPIURL = ""
                        saveSettings()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Informations")) {
                    Text("Finovera v1.0")
                        .font(.caption)
                    Text("© 2025 Jonathan Bouniol")
                        .font(.caption)
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
