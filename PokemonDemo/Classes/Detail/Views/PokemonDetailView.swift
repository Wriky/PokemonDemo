//
//  PokemonDetailView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct PokemonDetailView: View {
    @StateObject private var viewModel: PokemonDetailViewModel

    init(pokemon: Pokemon) {
        _viewModel = StateObject(wrappedValue: PokemonDetailViewModel(pokemon: pokemon))
    }

    var body: some View {
        List {
            Section("Pokemon") {
                Text(viewModel.title)
            }

            Section("Abilities") {
                if viewModel.abilitiesText.isEmpty {
                    Text("No abilities found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.abilitiesText, id: \.self) { ability in
                        Text(ability.capitalized)
                    }
                }
            }
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
