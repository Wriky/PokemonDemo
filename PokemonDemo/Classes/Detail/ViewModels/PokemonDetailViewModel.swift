//
//  PokemonDetailViewModel.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import Foundation
import Combine

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    let pokemon: Pokemon

    init(pokemon: Pokemon) {
        self.pokemon = pokemon
    }

    var title: String {
        pokemon.name.capitalized
    }

    var abilitiesText: [String] {
        pokemon.abilityNames
    }
}
