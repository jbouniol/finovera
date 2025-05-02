//
//  RegionPickerView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct RegionPickerView: View {
    @ObservedObject var vm: RecommendationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose investment regions")
                .font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(InvestmentRegion.allCases) { region in
                        RegionRow(region: region, isSelected: vm.regions.contains(region))
                            .onTapGesture { vm.toggleRegion(region) }
                    }
                }
            }

            Button("Validate") { dismiss() }
                .frame(maxWidth: .infinity).padding()
                .background(Color("Accent")).foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding().presentationDetents([.medium])
    }
}

