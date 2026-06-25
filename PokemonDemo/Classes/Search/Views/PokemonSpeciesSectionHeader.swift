//
//  PokemonSpeciesSectionHeader.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonSpeciesSectionHeader: View {
    let species: PokemonSpecies

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let colorName = species.color?.name {
                    Circle()
                        .fill(PokemonColorPalette.color(for: colorName))
                        .frame(width: 12, height: 12)
                        .accessibilityHidden(true)
                }

                Text("Species")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(.label))

                Text(species.name.capitalized)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color(.label))
            }

            Text("Capture Rate: \(species.captureRate ?? 0)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.label))

            Text(tapHint)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
    }

    private var tapHint: String {
        switch species.pokemons.count {
        case 0:
            return "No Pokémon forms found under this species."
        case 1:
            return "Tap the Pokémon below for details."
        default:
            return "\(species.pokemons.count) forms under this species — tap any name for details."
        }
    }
}
