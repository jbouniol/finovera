//
//  RecommendationCard.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        HStack(spacing: 16) {
            // Ticker badge
            VStack {
                Text(recommendation.symbol)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
                    .frame(width: 70, height: 70)
                    .background(actionColor)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }

            // Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(recommendation.qualityBadge)
                        .font(.caption2)
                        .foregroundColor(scoreColor)
                }

                HStack {
                    Text("\(Int(recommendation.score * 100))/100")
                        .font(.subheadline)
                        .foregroundColor(scoreColor)
                    
                    Spacer()
                    
                    Text(recommendation.recommendedAction)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(actionColor.opacity(0.2))
                        .foregroundColor(actionColor)
                        .clipShape(Capsule())
                }

                HStack {
                    Label(recommendation.sector, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Label(recommendation.region, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color("CardBG"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // Color based on score
    private var scoreColor: Color {
        recommendation.qualityColor
    }
    
    // Color based on action
    private var actionColor: Color {
        switch recommendation.recommendedAction {
        case "Acheter":
            return .green
        case "Renforcer":
            return Color.green.opacity(0.7)
        case "Garder":
            return .orange
        case "Vendre":
            return .red
        default:
            return .gray
        }
    }
}
