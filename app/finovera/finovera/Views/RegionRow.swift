//
//  RegionRow.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct RegionRow: View {
    let region: InvestmentRegion
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(region.flag)
            Text(region.name).fontWeight(.semibold)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(Color("Accent"))     // violet
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
