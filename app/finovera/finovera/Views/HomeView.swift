//
//  HomeView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUICore
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = RecommendationViewModel()
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var showStylePicker = false
    @State private var showRegionPicker = false
    @State private var showSectorPicker = false
    @State private var showAddTicker = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // — Greeting —
                VStack(alignment: .leading, spacing: 16) {
                    Image("FinoveraLogo")          // icône carré
                        .resizable().frame(width: 48, height: 48)
                    Text("Hello Jonathan !")
                        .font(.title).bold()
                }
                .padding(.horizontal)

                // — Liste des recos —
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(vm.recs) { rec in
                            NavigationLink { RecommendationDetailView(rec: rec) } label: {
                                RecommendationCard(rec: rec)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color("Background"))
            .overlay {
                if vm.isLoading {
                    LoadingView(message: "Finovera prépare une sélection d'actions grâce à l'IA…")
                }
            }


            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("HorizontalLogo")
                        .resizable().scaledToFit()
                        .frame(height: 82)               // ↑
                }


                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Investor style") { showStylePicker = true }
                        Button("Regions")        { showRegionPicker = true }
                        Button("Themes")         { showSectorPicker = true }
                        Divider()
                        Button("Add ticker…")    { showAddTicker = true }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showStylePicker) {
                InvestorStyleView(vm: vm)
            }
            .sheet(isPresented: $showRegionPicker) {
                RegionPickerView(vm: vm)
            }
            .sheet(isPresented: $showSectorPicker) {
                SectorPickerView(vm: vm)
            }
            .sheet(isPresented: $showAddTicker) { AddTickerView() }
            .alert("Offline mode – mock data", isPresented: $vm.showOfflineAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.offlineMessage ?? "Les recommandations affichées sont simulées.")
            }
            .task { vm.load() }
            .onAppear {
                guard onboardingDone == false else { return }      // ➜ plus de pop-up ensuite
                if vm.regions.isEmpty { showRegionPicker = true }
                else { showStylePicker = true }
            }
        }
    }
}
