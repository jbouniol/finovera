//
//  LoadingView.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.6)
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.headline)
            }
            .padding(32)
            .background(Color("CardBG"))
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .transition(.opacity)
    }
}
