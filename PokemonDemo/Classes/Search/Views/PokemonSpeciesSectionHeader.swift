//
//  PokemonSpeciesSectionHeader.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonSpeciesSectionHeader: View {
    let species: PokemonSpecies

    var body: some View {
        let accent = PokemonColorPalette.color(for: species.color?.name)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(format: "SPECIES #PCS-%03d", species.id))
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(accent)

                    Text(species.name.capitalized)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("CAPTURE")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(.secondary)

                    Text(PokemonSearchPresentation.captureRate(species.captureRate))
                        .font(.system(.title3, design: .monospaced, weight: .black))
                        .foregroundStyle(.primary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.caption)
                    .foregroundStyle(accent)

                Text(PokemonSearchPresentation.formHint(count: species.pokemons.count))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("COLOR \(species.color?.name.uppercased() ?? "UNKNOWN")")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accent.opacity(0.13))
                    )
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 18)
        .padding(.top, 18)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.13), accent.opacity(0.025)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .accessibilityElement(children: .combine)
    }
}
