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
            ZStack(alignment: .top) {
                PokemonSearchTheme.pageBackground
                    .ignoresSafeArea()

                headerBackground
                    .frame(height: 214)
                    .ignoresSafeArea(edges: .top)

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

    private var headerBackground: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(
                colors: [
                    PokemonSearchTheme.headerCoral,
                    PokemonSearchTheme.headerPeach
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PokeballMark()
                .frame(width: 172, height: 172)
                .foregroundStyle(.white.opacity(0.13))
                .offset(x: 36, y: 38)
        }
        .clipShape(.rect(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous))
        .shadow(color: PokemonSearchTheme.coral.opacity(0.16), radius: 16, y: 8)
    }

    private var pokedexHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 14) {
                PokedexLens()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pokédex")
                        .font(.system(.title, design: .rounded, weight: .black))

                    Text("SPECIES SCANNER")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(PokemonSearchTheme.headerInk.opacity(0.62))
                }

                Spacer()

                HStack(spacing: 7) {
                    indicator(color: PokemonSearchTheme.coral)
                    indicator(color: PokemonSearchTheme.butter)
                    indicator(color: PokemonSearchTheme.mint)
                }
            }

            searchControl
        }
        .foregroundStyle(PokemonSearchTheme.headerInk)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 22)
    }

    private var searchControl: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PokemonSearchTheme.coral)

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
                    .fill(Color(uiColor: .systemBackground).opacity(0.94))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            }
            .shadow(color: PokemonSearchTheme.coral.opacity(0.08), radius: 12, y: 6)

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
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            viewModel.isSearchDisabled
                                ? PokemonSearchTheme.headerInk.opacity(0.14)
                                : PokemonSearchTheme.sky
                        )
                )
                .shadow(color: PokemonSearchTheme.sky.opacity(viewModel.isSearchDisabled ? 0 : 0.24), radius: 10, y: 6)
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
                    .fill(PokemonSearchTheme.warning.opacity(0.11))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PokemonSearchTheme.warning.opacity(0.16), lineWidth: 1)
            }
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
                VStack(spacing: 8) {
                    ForEach(species.pokemons) { pokemon in
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
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PokemonSearchTheme.cardBackground)
        )
        .overlay(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(accent)
                .frame(width: 6)
                .padding(.vertical, 22)
                .padding(.leading, 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: PokemonSearchTheme.shadow, radius: 18, y: 9)
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
                        .foregroundStyle(PokemonSearchTheme.sky)
                    Text("DATABASE SCAN COMPLETE")
                } else {
                    Image(systemName: "wave.3.right")
                        .foregroundStyle(PokemonSearchTheme.coral)
                    Text("LOADING MORE RECORDS")
                }
            }
            .font(.system(.caption, design: .rounded, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(PokemonSearchTheme.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(PokemonSearchTheme.cardBackground.opacity(0.72))
            )
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
            .overlay(Circle().stroke(.white.opacity(0.76), lineWidth: 1))
            .shadow(color: color.opacity(0.32), radius: 3)
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
    static let pokedexRed = coral
    static let pokedexDarkRed = coralDeep
    static let screenBlue = sky
    static let coral = Color(red: 1.0, green: 0.29, blue: 0.33)
    static let coralDeep = Color(red: 0.86, green: 0.13, blue: 0.22)
    static let headerCoral = Color(red: 1.0, green: 0.39, blue: 0.43)
    static let headerPeach = Color(red: 1.0, green: 0.52, blue: 0.47)
    static let sky = Color(red: 0.12, green: 0.58, blue: 0.80)
    static let butter = Color(red: 1.0, green: 0.79, blue: 0.28)
    static let mint = Color(red: 0.43, green: 0.78, blue: 0.58)
    static let headerCream = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 1)
                : UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1)
        }
    )
    static let headerBlush = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.24, green: 0.12, blue: 0.13, alpha: 1)
                : UIColor(red: 1.0, green: 0.82, blue: 0.80, alpha: 1)
        }
    )
    static let headerInk = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1)
                : UIColor.white
        }
    )
    static let cardBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.125, blue: 0.14, alpha: 1)
                : UIColor(red: 1.0, green: 0.985, blue: 0.955, alpha: 1)
        }
    )
    static let pageBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.07, green: 0.075, blue: 0.085, alpha: 1)
                : UIColor(red: 0.98, green: 0.94, blue: 0.88, alpha: 1)
        }
    )
    static let ink = Color(uiColor: .label)
    static let inkMuted = Color(uiColor: .secondaryLabel)
    static let divider = Color(red: 1.0, green: 0.29, blue: 0.33).opacity(0.10)
    static let warning = Color(red: 0.92, green: 0.53, blue: 0.08)
    static let shadow = Color.black.opacity(0.10)
}

private struct PokedexLens: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, PokemonSearchTheme.sky.opacity(0.9)],
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
        .frame(width: 50, height: 50)
        .shadow(color: PokemonSearchTheme.sky.opacity(0.24), radius: 8, y: 4)
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
                .fill(PokemonSearchTheme.coralDeep)
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
