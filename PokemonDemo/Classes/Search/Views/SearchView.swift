//
//  SearchView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

enum PokemonSearchPresentation {
    static func formHint(count: Int) -> String {
        "\(count) discovered \(count == 1 ? "form" : "forms")"
    }

    static func captureRate(_ value: Int?) -> String {
        value.map(String.init) ?? "—"
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var searchDebouncer = SearchDebouncer()
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                PokemonSearchTheme.pageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    pokedexHeader

                    ScrollView {
                        LazyVStack(spacing: 18) {
                            statusContent

                            ForEach(viewModel.speciesList) { species in
                                speciesCard(species)
                            }

                            paginationFooter
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onDisappear {
                searchDebouncer.cancel()
            }
        }
        .tint(PokemonSearchTheme.pokedexRed)
    }

    private var pokedexHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                PokedexLens()

                VStack(alignment: .leading, spacing: 2) {
                    Text("POKÉDEX")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .tracking(1.4)

                    Text("SPECIES SCANNER")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                HStack(spacing: 7) {
                    indicator(color: .red)
                    indicator(color: .yellow)
                    indicator(color: .green)
                }
            }

            searchControl
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background {
            ZStack(alignment: .trailing) {
                LinearGradient(
                    colors: [
                        PokemonSearchTheme.pokedexRed,
                        PokemonSearchTheme.pokedexDarkRed
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                PokeballMark()
                    .frame(width: 154, height: 154)
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: 34, y: 28)
            }
            .ignoresSafeArea(edges: .top)
        }
        .shadow(color: PokemonSearchTheme.pokedexDarkRed.opacity(0.22), radius: 12, y: 7)
    }

    private var searchControl: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PokemonSearchTheme.inkMuted)

                TextField("Search a Pokémon species", text: $viewModel.keyword)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(PokemonSearchTheme.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !viewModel.keyword.isEmpty {
                    Button {
                        viewModel.keyword = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(PokemonSearchTheme.inkMuted.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }

            Button {
                performSearch()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "scope")
                            .font(.system(size: 19, weight: .bold))
                    }
                }
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            viewModel.isSearchDisabled
                                ? Color.white.opacity(0.18)
                                : PokemonSearchTheme.screenBlue
                        )
                )
            }
            .buttonStyle(PokedexPressButtonStyle())
            .disabled(viewModel.isSearchDisabled || viewModel.isLoading)
            .accessibilityLabel("Search")
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        if let errorMessage = viewModel.errorMessage {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(PokemonSearchTheme.warning)

                VStack(alignment: .leading, spacing: 3) {
                    Text("SCAN INTERRUPTED")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .tracking(0.8)

                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(PokemonSearchTheme.inkMuted)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PokemonSearchTheme.warning.opacity(0.12))
            )
        } else if !viewModel.isLoading && viewModel.speciesList.isEmpty {
            EmptySearchStateView(
                title: viewModel.hasSearched ? "No Match Detected" : "Scanner Ready",
                message: viewModel.hasSearched
                    ? "Try another species name or check the spelling."
                    : "Enter a species name to explore every discovered form."
            )
        }
    }

    private func speciesCard(_ species: PokemonSpecies) -> some View {
        let accent = PokemonColorPalette.color(for: species.color?.name)

        return VStack(spacing: 0) {
            PokemonSpeciesSectionHeader(species: species)

            if species.pokemons.isEmpty {
                Text("No Pokémon forms found")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(PokemonSearchTheme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(species.pokemons.enumerated()), id: \.element.id) { index, pokemon in
                        NavigationLink {
                            PokemonDetailView(
                                pokemonID: pokemon.id,
                                placeholderName: pokemon.name.capitalized
                            )
                        } label: {
                            PokemonSearchRow(
                                pokemon: pokemon,
                                accentColor: accent
                            )
                        }
                        .buttonStyle(.plain)

                        if index < species.pokemons.count - 1 {
                            Divider()
                                .overlay(PokemonSearchTheme.divider)
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent)
                .frame(width: 5)
                .padding(.vertical, 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: PokemonSearchTheme.shadow, radius: 14, y: 7)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.shouldShowLoadMore || viewModel.shouldShowNoMoreData {
            HStack(spacing: 10) {
                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(PokemonSearchTheme.pokedexRed)
                    Text("SCANNING NEXT SECTOR")
                } else if viewModel.shouldShowNoMoreData {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(PokemonSearchTheme.screenBlue)
                    Text("DATABASE SCAN COMPLETE")
                } else {
                    Image(systemName: "wave.3.right")
                        .foregroundStyle(PokemonSearchTheme.pokedexRed)
                    Text("LOADING MORE RECORDS")
                }
            }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(PokemonSearchTheme.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .task {
                guard viewModel.shouldShowLoadMore else { return }
                await viewModel.loadMore()
            }
        }
    }

    private func indicator(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(.black.opacity(0.18), lineWidth: 1))
            .shadow(color: color.opacity(0.6), radius: 3)
            .accessibilityHidden(true)
    }

    private func performSearch() {
        guard !viewModel.isSearchDisabled, !viewModel.isLoading else { return }
        isSearchFieldFocused = false

        searchDebouncer.schedule {
            await viewModel.search()
        }
    }
}

private enum PokemonSearchTheme {
    static let pokedexRed = Color(red: 0.90, green: 0.12, blue: 0.17)
    static let pokedexDarkRed = Color(red: 0.58, green: 0.04, blue: 0.09)
    static let screenBlue = Color(red: 0.08, green: 0.57, blue: 0.78)
    static let pageBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.055, green: 0.07, blue: 0.09, alpha: 1)
                : UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        }
    )
    static let ink = Color(uiColor: .label)
    static let inkMuted = Color(uiColor: .secondaryLabel)
    static let divider = Color(uiColor: .separator).opacity(0.45)
    static let warning = Color(red: 0.92, green: 0.53, blue: 0.08)
    static let shadow = Color.black.opacity(0.08)
}

private struct PokedexLens: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, PokemonSearchTheme.screenBlue.opacity(0.9)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 28
                    )
                )
                .padding(5)

            Circle()
                .stroke(.black.opacity(0.18), lineWidth: 2)
                .padding(5)
        }
        .frame(width: 48, height: 48)
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}

private struct PokeballMark: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 16)

            Rectangle()
                .frame(height: 16)

            Circle()
                .fill(PokemonSearchTheme.pokedexDarkRed)
                .frame(width: 54, height: 54)

            Circle()
                .stroke(lineWidth: 12)
                .frame(width: 54, height: 54)
        }
        .accessibilityHidden(true)
    }
}

private struct PokedexPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
