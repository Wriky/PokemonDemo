//
//  PokemonArtworkView.swift
//  PokemonDemo
//

import SwiftUI

struct PokemonArtworkView: View {
    let pokemonID: Int
    let colorName: String?

    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Pokemon artwork")
            } else if isLoading {
                loadingView
            } else if loadFailed {
                failedView
            } else {
                artworkPlaceholder
            }
        }
        .frame(maxWidth: 240, maxHeight: 240)
        .task(id: pokemonID) {
            await loadArtwork()
        }
    }

    private var loadingView: some View {
        ZStack {
            artworkPlaceholder
            ProgressView()
                .controlSize(.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Pokemon artwork")
    }

    private var failedView: some View {
        VStack(spacing: 10) {
            artworkPlaceholder

            Button("Retry Image") {
                Task {
                    await loadArtwork(force: true)
                }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pokemon artwork unavailable")
    }

    private var artworkPlaceholder: some View {
        ZStack {
            Color.clear
            
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(heroTint)
        }
    }

    private var heroTint: Color {
        PokemonColorPalette.color(for: colorName)
    }

    private func loadArtwork(force: Bool = false) async {
        if force {
            image = nil
        }

        isLoading = true
        loadFailed = false

        let loadedImage = await PokemonArtworkLoader.loadImage(for: pokemonID)

        guard !Task.isCancelled else { return }

        image = loadedImage
        isLoading = false
        loadFailed = loadedImage == nil
    }
}
