//
//  SectorPickerView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct SectorPickerView: View {
    @ObservedObject var vm: RecommendationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose your themes")
                .font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Sector.allCases) { s in
                        SectorRow(sector: s, isSelected: vm.sectors.contains(s))
                            .onTapGesture { vm.toggleSector(s) }
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
