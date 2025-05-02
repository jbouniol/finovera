//
//  ContentView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct ContentView: View {
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
                    Label("Portefeuille", systemImage: "briefcase.fill")
                }
        }
        .tint(Color("Accent"))           // accent vert-turquoise
        .background(Color("Background"))
        .preferredColorScheme(.dark)     // force dark (Trade Republic)
    }
}
