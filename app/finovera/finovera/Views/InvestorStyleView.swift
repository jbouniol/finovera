//
//  InvestorStyleView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct InvestorStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: RecommendationViewModel
    @AppStorage("onboardingDone") private var onboardingDone = false

    // État local pour le slider (50-100)
    @State private var draftCapital: Double

    init(vm: RecommendationViewModel) {
        self.vm = vm
        _draftCapital = State(initialValue: vm.capitalTarget)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {

                // -- TITRE --------------------------------------------------
                VStack(alignment: .leading, spacing: 6) {
                    Text("Select an investor style")
                        .font(.largeTitle).bold()
                    Text("Choose how much capital you wish to preserve. Finovera adapts the risk accordingly.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // -- LISTE STATIC ------------------------------------------
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(InvestorStyle.allCases) { style in
                            InvestorStyleRow(style: style,
                                             isSelected: style == vm.risk,
                                             capital: draftCapital)    // cercle live
                        }
                    }
                }

                // -- SLIDER & RISK ----------------------------------------
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Capital preservation")
                        Spacer()
                        Text("\(Int(draftCapital)) %").bold()
                    }
                    Slider(value: $draftCapital, in: 50...100, step: 1)
                        .tint(Color("Accent"))

                    Text("Risk level : **\(InvestorStyle.fromCapital(draftCapital).title)**")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding()
                .background(Color("CardBG"))
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // -- BOUTON VALIDATE (déclenche chargement) ---------------
                Button {
                    withAnimation { vm.isLoading = true }          // popup ici
                    vm.updateCapitalTarget(draftCapital) {         // 👇 callback
                        withAnimation { vm.isLoading = false }
                        onboardingDone = true
                        dismiss()
                    }
                } label: {
                    Text("Validate")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color("Accent"))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .interactiveDismissDisabled()          // ⬅️ plus de fermeture au swipe
            .overlay {
                if vm.isLoading {
                    LoadingView(message: "Finovera prépare une sélection d’actions grâce à l’IA…")
                }
            }
            .presentationDetents([.large])
        }
    }
}

extension InvestorStyle {
    static func fromCapital(_ cap: Double) -> InvestorStyle {
        switch cap {
        case 86...100: return .conservative
        case 76...85:  return .balanced
        default:       return .aggressive
        }
    }
}
