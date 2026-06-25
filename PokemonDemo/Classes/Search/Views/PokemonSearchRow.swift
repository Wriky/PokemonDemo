//
//  PokemonSearchRow.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonSearchRow: View {
    let pokemon: Pokemon
    var accentColor: Color = .red

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.14))

                PokeballGlyph()
                    .foregroundStyle(accentColor)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 7) {
                Text(pokemon.name.capitalized)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                abilityLabels
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(accentColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(accentColor.opacity(0.11))
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Pokémon detail")
    }

    @ViewBuilder
    private var abilityLabels: some View {
        if pokemon.abilityNames.isEmpty {
            Text("ABILITY DATA UNAVAILABLE")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 6) {
                ForEach(Array(pokemon.abilityNames.prefix(2)), id: \.self) { ability in
                    Text(ability.replacingOccurrences(of: "-", with: " ").uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.35)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(uiColor: .tertiarySystemFill))
                        )
                }

                if pokemon.abilityNames.count > 2 {
                    Text("+\(pokemon.abilityNames.count - 2)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PokeballGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2.5)

            Rectangle()
                .frame(height: 2.5)

            Circle()
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .frame(width: 10, height: 10)

            Circle()
                .stroke(lineWidth: 2.5)
                .frame(width: 10, height: 10)
        }
        .accessibilityHidden(true)
    }
}
