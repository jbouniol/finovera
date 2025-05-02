//
//  LogHeader.swift
//  finovera
//
//  Created by Jonathan Bouniol on 30/04/2025.
//

import SwiftUI

struct LogoHeader: View {
    var body: some View {
        Image("FinoveraLogo")
            .resizable()
            .scaledToFit()
            .frame(height: 28)
            .padding(.top, 4)
    }
}
