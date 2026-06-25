//
//  SearchView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var searchDebouncer = SearchDebouncer()
    @FocusState private var isSearchFieldFocused: Bool
    private let colorOpacity = 0.5

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBarSection

                List {
                    if !viewModel.isLoading && viewModel.speciesList.isEmpty {
                        Section {
                            EmptySearchStateView(
                                title: viewModel.hasSearched ? "No Results Found" : "Ready to Search",
                                message: viewModel.hasSearched
                                    ? "Try another Pokemon species name."
                                    : "Enter a species name and tap Search."
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }

                    ForEach(viewModel.speciesList) { species in
                        Section {
                            ForEach(species.pokemons) { pokemon in
                                NavigationLink {
                                    PokemonDetailView(
                                        pokemonID: pokemon.id,
                                        placeholderName: pokemon.name.capitalized
                                    )
                                } label: {
                                    PokemonSearchRow(pokemon: pokemon)
                                }
                                .listRowBackground(rowBackgroundColor(for: species.color?.name))
                            }
                        } header: {
                            PokemonSpeciesSectionHeader(species: species)
                        }
                    }

                    if viewModel.shouldShowLoadMore || viewModel.shouldShowNoMoreData {
                        Section {
                            HStack {
                                Spacer()
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                } else if viewModel.shouldShowNoMoreData {
                                    Text("No more data")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Loading more...")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .task {
                                guard viewModel.shouldShowLoadMore else { return }
                                await viewModel.loadMore()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Pokemon Search")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                searchDebouncer.cancel()
            }
        }
    }

    private var searchBarSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("Search Pokemon species", text: $viewModel.keyword)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                Button("Search") {
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSearchDisabled || viewModel.isLoading)
            }

            if viewModel.isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Searching...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(uiColor: .systemBackground))
    }

    private func performSearch() {
        guard !viewModel.isSearchDisabled, !viewModel.isLoading else { return }
        isSearchFieldFocused = false

        searchDebouncer.schedule {
            await viewModel.search()
        }
    }

    private func rowBackgroundColor(for colorName: String?) -> Color {
        PokemonColorPalette.background(for: colorName, opacity: colorOpacity)
    }
}
