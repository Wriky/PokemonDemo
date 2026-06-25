//
//  PokemonModels.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import Foundation

struct PokemonSpecies: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let captureRate: Int?
    let color: PokemonColor?
    let pokemons: [Pokemon]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case captureRate = "capture_rate"
        case color = "pokemon_v2_pokemoncolor"
        case pokemons = "pokemon_v2_pokemons"
    }
}

struct PokemonColor: Hashable, Decodable {
    let id: Int
    let name: String
}

struct Pokemon: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let abilities: [PokemonAbilityEntry]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case abilities = "pokemon_v2_pokemonabilities"
    }

    var abilityNames: [String] {
        abilities.compactMap { $0.ability?.name }
    }
}

struct PokemonAbilityEntry: Identifiable, Hashable, Decodable {
    let id: Int
    let ability: Ability?

    enum CodingKeys: String, CodingKey {
        case id
        case ability = "pokemon_v2_ability"
    }
}

struct Ability: Hashable, Decodable {
    let name: String
}
