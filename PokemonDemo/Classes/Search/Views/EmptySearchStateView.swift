//
//  EmptySearchStateView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct EmptySearchStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
