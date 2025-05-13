//
//  finoveraApp.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

@main
struct finoveraApp: App {
    @State private var showSplash = true
    @AppStorage("apiBaseURL") var apiBaseURLString: String = ""
    
    init() {
        // Configuration de l'URL de l'API au démarrage
        setupAPIConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .onAppear {
                        // Rafraîchir la configuration de l'API à chaque apparition
                        setupAPIConfiguration()
                    }
                if showSplash {
                    Color("BG").ignoresSafeArea()
                    Image("HorizontalLogo")
                        .resizable().scaledToFit()
                        .padding(30)
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.0)) {
                                showSplash = false
                            }
                        }
                }
            }
        }
    }
    
    /// Configure l'URL de base de l'API
    private func setupAPIConfiguration() {
        // Si une URL personnalisée est définie dans les préférences, l'utiliser
        if !apiBaseURLString.isEmpty, let url = URL(string: apiBaseURLString) {
            print("[CONFIG] Utilisation de l'URL API personnalisée: \(url.absoluteString)")
            APIService.customBaseURL = url
        }
        
        #if DEBUG
        // En mode DEBUG, afficher l'URL utilisée dans la console
        if let customURL = APIService.customBaseURL {
            print("[CONFIG] URL API: \(customURL.absoluteString) (personnalisée)")
        } else {
            print("[CONFIG] URL API: \(APIService.baseURLForDebug.absoluteString) (par défaut)")
        }
        #endif
    }
}
