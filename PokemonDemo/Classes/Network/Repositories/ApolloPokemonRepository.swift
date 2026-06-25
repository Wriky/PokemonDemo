//
//  ApolloPokemonRepository.swift
//  PokemonDemo
//

import Apollo
import ApolloAPI
import Foundation

struct ApolloPokemonRepository: PokemonRepositoryProtocol {
    private let client: ApolloClient

    init(client: ApolloClient = ApolloClientProvider.shared) {
        self.client = client
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        let query = PokemonAPI.SearchPokemonSpeciesQuery(
            pattern: "%\(keyword)%",
            limit: Int32(limit),
            offset: Int32(offset)
        )
        let response = try await fetch(query: query)
        let species = response.data?.pokemon_v2_pokemonspecies ?? []
        return species.map(mapSpecies)
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetail {
        let query = PokemonAPI.PokemonDetailQuery(id: Int32(id))
        let response = try await fetch(query: query)

        guard let pokemon = response.data?.pokemon_v2_pokemon_by_pk else {
            throw PokemonRepositoryError.noData
        }

        return mapDetail(pokemon)
    }

    private func fetch<Query: GraphQLQuery>(
        query: Query
    ) async throws -> GraphQLResponse<Query> where Query.ResponseFormat == SingleResponseFormat {
        var lastResponse: GraphQLResponse<Query>?

        for try await response in try client.fetch(
            query: query,
            cachePolicy: .cacheAndNetwork
        ) {
            lastResponse = response
        }

        guard let lastResponse else {
            throw PokemonRepositoryError.noData
        }

        if let message = lastResponse.errors?.first?.message {
            throw PokemonRepositoryError.graphQL(message)
        }

        return lastResponse
    }

    private func mapSpecies(
        _ species: PokemonAPI.SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy
    ) -> PokemonSpecies {
        PokemonSpecies(
            id: species.id,
            name: species.name,
            captureRate: species.capture_rate,
            color: species.pokemon_v2_pokemoncolor.map {
                PokemonColor(id: $0.id, name: $0.name)
            },
            pokemons: species.pokemon_v2_pokemons.map(mapPokemon)
        )
    }

    private func mapPokemon(
        _ pokemon: PokemonAPI.SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon
    ) -> Pokemon {
        Pokemon(
            id: pokemon.id,
            name: pokemon.name,
            abilityNames: pokemon.pokemon_v2_pokemonabilities.compactMap { $0.pokemon_v2_ability?.name }
        )
    }

    private func mapDetail(
        _ pokemon: PokemonAPI.PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk
    ) -> PokemonDetail {
        PokemonDetail(
            id: pokemon.id,
            name: pokemon.name,
            abilityNames: pokemon.pokemon_v2_pokemonabilities.compactMap { $0.pokemon_v2_ability?.name },
            typeNames: pokemon.pokemon_v2_pokemontypes.compactMap { $0.pokemon_v2_type?.name },
            height: pokemon.height,
            weight: pokemon.weight,
            captureRate: pokemon.pokemon_v2_pokemonspecy?.capture_rate,
            colorName: pokemon.pokemon_v2_pokemonspecy?.pokemon_v2_pokemoncolor?.name
        )
    }
}
