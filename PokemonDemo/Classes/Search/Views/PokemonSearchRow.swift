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
            PokemonSearchAvatar(
                pokemonID: pokemon.id,
                accentColor: accentColor
            )

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
                        .fill(accentColor.opacity(0.14))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(rowBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.11), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Pokémon detail")
    }

    private var rowBackground: Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.155, green: 0.16, blue: 0.18, alpha: 1)
                    : UIColor(red: 1.0, green: 0.965, blue: 0.925, alpha: 1)
            }
        )
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
                                .fill(accentColor.opacity(0.13))
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        }
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

private struct PokemonSearchAvatar: View {
    let pokemonID: Int
    let accentColor: Color

    @State private var image: UIImage?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.22),
                            Color.white.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(.white.opacity(0.78), lineWidth: 2)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                PokeballGlyph()
                    .foregroundStyle(accentColor)
                    .frame(width: loadFailed ? 25 : 22, height: loadFailed ? 25 : 22)
                    .opacity(loadFailed ? 0.9 : 0.55)
            }
        }
        .frame(width: 54, height: 54)
        .shadow(color: accentColor.opacity(0.18), radius: 9, y: 5)
        .task(id: pokemonID) {
            await loadArtwork()
        }
        .accessibilityHidden(true)
    }

    private func loadArtwork() async {
        image = nil
        loadFailed = false

        let loadedImage = await PokemonArtworkLoader.loadImage(for: pokemonID)

        guard !Task.isCancelled else { return }

        image = loadedImage
        loadFailed = loadedImage == nil
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
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 10, height: 10)

            Circle()
                .stroke(lineWidth: 2.5)
                .frame(width: 10, height: 10)
        }
        .accessibilityHidden(true)
    }
}
