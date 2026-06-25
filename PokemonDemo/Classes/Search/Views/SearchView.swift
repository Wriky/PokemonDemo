//
//  SearchView.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFieldFocused: Bool
    private let defaultRowColor = Color(uiColor: .secondarySystemBackground)
    private let colorMap: [String: Color] = [
        "black": Color.black.opacity(0.18),
        "blue": Color.blue.opacity(0.18),
        "brown": Color.brown.opacity(0.18),
        "gray": Color.gray.opacity(0.18),
        "green": Color.green.opacity(0.18),
        "pink": Color.pink.opacity(0.18),
        "purple": Color.purple.opacity(0.18),
        "red": Color.red.opacity(0.18),
        "white": Color(uiColor: .systemBackground),
        "yellow": Color.yellow.opacity(0.18)
    ]

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
                                    PokemonDetailView(pokemon: pokemon)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(pokemon.name.capitalized)
                                            .font(.headline)

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
                                }
                                .listRowBackground(rowBackgroundColor(for: species.color?.name))
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(species.name.capitalized)
                                    .font(.headline)
                                Text("Capture Rate: \(species.captureRate ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
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
        isSearchFieldFocused = false

        Task {
            await viewModel.search()
        }
    }

    private func rowBackgroundColor(for colorName: String?) -> Color {
        guard let colorName else {
            return defaultRowColor
        }

        return colorMap[colorName.lowercased()] ?? defaultRowColor
    }
}
