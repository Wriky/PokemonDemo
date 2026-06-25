//
//  PokemonModels.swift
//  PokemonDemo
//

import Foundation

struct PokemonSpecies: Identifiable, Hashable, Sendable, Equatable {
    let id: Int
    let name: String
    let captureRate: Int?
    let color: PokemonColor?
    let pokemons: [Pokemon]
}

struct PokemonColor: Hashable, Sendable, Equatable {
    let id: Int
    let name: String
}

struct Pokemon: Identifiable, Hashable, Sendable, Equatable {
    let id: Int
    let name: String
    let abilityNames: [String]
}

struct PokemonDetail: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
    let typeNames: [String]
    let height: Int?
    let weight: Int?
    let captureRate: Int?
    let colorName: String?

    var artworkURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
}
