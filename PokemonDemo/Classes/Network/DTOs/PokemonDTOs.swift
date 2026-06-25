import Foundation

nonisolated struct PokemonSpeciesDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let captureRate: Int?
    let color: PokemonColorDTO?
    let pokemons: [PokemonDTO]
}

nonisolated struct PokemonColorDTO: Equatable, Sendable {
    let id: Int
    let name: String
}

nonisolated struct PokemonDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
}

nonisolated struct PokemonDetailDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
    let typeNames: [String]
    let height: Int?
    let weight: Int?
    let captureRate: Int?
    let colorName: String?
}
