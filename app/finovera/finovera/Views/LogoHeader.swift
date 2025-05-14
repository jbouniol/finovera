//
//  LogHeader.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct LogoHeader: View {
    @State private var animate = false
    
    var body: some View {
        Image("HorizontalLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 80)
            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
            .scaleEffect(animate ? 1.02 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
            .padding(.vertical, 16)
    }
}

#Preview {
    LogoHeader()
        .background(Color("Background"))
}
