//
//  PokemonDetailViewModel.swift
//  PokemonDemo
//

import Foundation
import Combine

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published private(set) var detail: PokemonDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let placeholderName: String
    private let pokemonID: Int
    private let repository: any PokemonRepositoryProtocol

    init(
        pokemonID: Int,
        placeholderName: String,
        repository: any PokemonRepositoryProtocol = PokemonRepository.production
    ) {
        self.pokemonID = pokemonID
        self.placeholderName = placeholderName
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await repository.pokemonDetail(id: pokemonID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
