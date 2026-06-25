import Foundation

nonisolated protocol PokemonGraphQLExecuting: Sendable {
    func searchSpecies(
        pattern: String,
        limit: Int,
        offset: Int
    ) async throws -> PokemonAPI.SearchPokemonSpeciesQuery.Data

    func pokemonDetail(id: Int) async throws -> PokemonAPI.PokemonDetailQuery.Data
}
