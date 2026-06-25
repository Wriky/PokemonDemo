//
//  PokemonSearchRow.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonSearchRow: View {
    let pokemon: Pokemon

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(pokemon.name.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if pokemon.abilityNames.isEmpty {
                    Text("No abilities found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(pokemon.abilityNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Pokemon detail")
    }
}
