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
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
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
}
