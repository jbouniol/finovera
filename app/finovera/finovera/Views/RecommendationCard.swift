//
//  RecommendationCard.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct RecommendationCard: View {
    let rec: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rec.symbol)
                    .font(.title2).bold()
                    .foregroundColor(.white)               // ⬅︎ force blanc
                Spacer()
                Text(String(format: "%.0f", rec.score))
                    .font(.subheadline).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(scoreColor.opacity(0.2))
                    .clipShape(.capsule)
            }
            Text(rec.name)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))      // titre second
            Text(rec.reason)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color("Background").opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }


    private var scoreColor: Color {
        switch rec.score {
        case 0..<40:  return .red
        case 40..<70: return .orange
        default:      return .green
        }
    }
}
