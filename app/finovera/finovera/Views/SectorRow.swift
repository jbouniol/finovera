
//
//  SectorRow.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//


import SwiftUI

struct SectorRow: View {
    let sector: Sector
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(sector.rawValue).fontWeight(.semibold)
            Spacer()
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(Color("Accent"))
        }
        .padding()
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
