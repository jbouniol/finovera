//
//  PortfolioView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI
import Charts   // Xcode 15 / iOS 17

struct PortfolioView: View {
    @State private var totalValue: Double = 43_500
    @State private var dailyPnL: Double = 2.6        // %

    struct Holding: Identifiable {
        let id = UUID()
        let symbol: String
        let quantity: Double
        let value: Double
        let sector: Sector
    }
    @State private var holdings: [Holding] = [
        .init(symbol: "AAPL", quantity: 35, value: 6500, sector: .technology),
        .init(symbol: "MSFT", quantity: 18, value: 6300, sector: .technology),
        .init(symbol: "XOM",  quantity: 40, value: 4300, sector: .energy),
        .init(symbol: "BNP",  quantity: 120, value: 3700, sector: .banks)
    ]

    // simulation 30 jours
    private let history: [(Date, Double)] = {
        (0..<30).map { i in
            (Calendar.current.date(byAdding: .day, value: -i, to: .now)!, 38000 + Double.random(in: -1500...3500))
        }.reversed()
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // ------ résumé ------
                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio value").font(.headline)
                    Text("$\(Int(totalValue))")
                        .font(.largeTitle).bold()
                    HStack {
                        Image(systemName: dailyPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.2f %%", dailyPnL))
                    }
                    .foregroundColor(dailyPnL >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ------ chart ------
                Chart {
                    ForEach(history, id: \.0) { point in
                        LineMark(
                            x: .value("Date", point.0),
                            y: .value("Value", point.1)
                        )
                    }
                }
                .frame(height: 200)
                .chartXAxis(.hidden).chartYAxis(.hidden)

                // ------ répartition sectorielle ------
                VStack(alignment: .leading, spacing: 8) {
                    Text("Allocation by sector").font(.headline)
                    PieChart(data: holdings.reduce(into: [:]) { $0[$1.sector, default: 0] += $1.value })
                        .frame(height: 200)
                }

                // ------ table des positions ------
                VStack(alignment: .leading, spacing: 12) {
                    Text("Holdings").font(.headline)
                    ForEach(holdings) { h in
                        HStack {
                            Text(h.symbol).fontWeight(.bold)
                            Spacer()
                            Text(String(format: "$%.0f", h.value))
                        }
                        .padding()
                        .background(Color("CardBG"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("BG"))
    }
}

/// Mini pie-chart SwiftUI
struct PieChart: View {
    let data: [Sector: Double]

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            let total  = data.values.reduce(0, +)
            let values = Array(data)
            let angles = values.scan(Angle(degrees: 0)) { acc, element in
                acc + .degrees(360 * (element.value / total))
            }

            ZStack {
                ForEach(Array(zip(values.indices, values)), id: \.1.0) { idx, element in
                    let start = angles[idx]
                    let end   = angles[idx + 1]
                    Path { p in
                        p.move(to: .init(x: radius, y: radius))
                        p.addArc(center: .init(x: radius, y: radius),
                                 radius: radius,
                                 startAngle: start, endAngle: end, clockwise: false)
                    }
                    .fill(gradient(for: element.key))
                }
            }
        }
    }

    private func gradient(for sector: Sector) -> LinearGradient {
        let color = Color("Accent")
        return LinearGradient(colors: [color.opacity(0.6), color],
                              startPoint: .top, endPoint: .bottom)
    }
}

private extension Array {
    /// cumulatif pour le pie
    func scan<T>(_ initial: T, _ transform: (T, Element) -> T) -> [T] {
        var running = initial
        return [initial] + map { running = transform(running, $0); return running }
    }
}
