//
//  WelcomeView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome to Pokemon Search")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Search Pokemon species and view simple detail information.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Spacer()

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
