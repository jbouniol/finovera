//
//  InvestorStyleRow.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

import SwiftUI

struct InvestorStyleRow: View {
    let style: InvestorStyle             // conservative / balanced / aggressive
    let isSelected: Bool
    let capital: Double                  // valeur courante du slider (50-100)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            //-- HEAD ---------------------------------------------------------
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(style.title).fontWeight(.semibold)
                    Text(style.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // coche si sélectionné
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("Accent"))
                }
            }

            //-- GAUGES (uniquement sur la ligne sélectionnée) ---------------
            if isSelected {
                let cap = Int(capital)
                let risk = 100 - cap
                HStack(spacing: 32) {
                    gauge(value: cap,  label: "Capital\npreservation")
                    gauge(value: risk, label: "Risk\nlevel")
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut, value: isSelected)
        .padding()
        .background(isSelected ? Color("CardBG") : Color("CardBG").opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: – little circular gauge
    private func gauge(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.18), lineWidth: 4)
                Circle().trim(from: 0, to: CGFloat(value) / 100)
                    .stroke(Color("Accent"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(value)%").font(.caption2)
            }.frame(width: 56, height: 56)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
    }
}
