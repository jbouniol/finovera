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
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    // Completion handler called when a ticker is successfully added
    var onTickerAdded: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Ticker (ex : TSLA)", text: $ticker)
                    .textInputAutocapitalization(.characters)
                    .font(.title2).padding()
                    .background(Color("CardBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Add") {
                    addTicker()
                }
                .disabled(ticker.isEmpty || isSubmitting)
                .frame(maxWidth: .infinity).padding()
                .background(Color("Accent")).foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding()
            .navigationTitle("Add a security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isSubmitting {
                    LoadingView(message: "Ajout du ticker…")
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Une erreur est survenue")
            }
        }
    }
    
    private func addTicker() {
        Task {
            withAnimation { isSubmitting = true }
            do {
                try await APIService.addTicker(ticker.uppercased())
                withAnimation { isSubmitting = false }
                
                // Call completion handler if provided
                if let onTickerAdded = onTickerAdded {
                    onTickerAdded(ticker.uppercased())
                } else {
                    dismiss()
                }
            } catch {
                errorMessage = "Échec de l'ajout: \(error.localizedDescription)"
                showError = true
                withAnimation { isSubmitting = false }
            }
        }
    }
}
