//
//  PokemonArtworkView.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonArtworkView: View {
    let url: URL?
    let colorName: String?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("Pokemon artwork")
                    case .failure:
                        artworkPlaceholder
                    case .empty:
                        ProgressView()
                            .accessibilityLabel("Loading Pokemon artwork")
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(maxWidth: 240, maxHeight: 240)
    }

    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(heroTint.opacity(0.25))
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(heroTint)
        }
        .accessibilityLabel("Pokemon artwork unavailable")
    }

    private var heroTint: Color {
        PokemonColorPalette.color(for: colorName)
    }
}
