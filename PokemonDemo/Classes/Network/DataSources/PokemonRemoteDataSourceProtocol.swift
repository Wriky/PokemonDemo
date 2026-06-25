import Foundation

nonisolated protocol PokemonRemoteDataSourceProtocol: Sendable {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpeciesDTO]
    func pokemonDetail(id: Int) async throws -> PokemonDetailDTO
}

nonisolated enum PokemonRemoteDataSourceError: Error, Equatable, Sendable {
    case noData
    case graphQL(String)
    case transport(String)
}
