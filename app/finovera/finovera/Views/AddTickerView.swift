//
//  AddTickerView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct AddTickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ticker = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Ticker (ex : TSLA)", text: $ticker)
                    .textInputAutocapitalization(.characters)
                    .font(.title2).padding()
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Add") {
                    Task {
                        withAnimation { isSubmitting = true }
                        try? await APIService.addTicker(ticker.uppercased())
                        withAnimation { isSubmitting = false }
                        dismiss()
                    }
                }
                .disabled(ticker.isEmpty || isSubmitting)
                .disabled(ticker.isEmpty)
                .frame(maxWidth: .infinity).padding()
                .background(Color("Accent")).foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding()
            .navigationTitle("Add a security")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isSubmitting {
                    LoadingView(message: "Ajout du ticker…")
                }
            }

        }

    }
}
