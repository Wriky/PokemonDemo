import Foundation

nonisolated struct ApolloPokemonRemoteDataSource: PokemonRemoteDataSourceProtocol {
    private let executor: any PokemonGraphQLExecuting

    init(executor: any PokemonGraphQLExecuting = ApolloPokemonGraphQLExecutor()) {
        self.executor = executor
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpeciesDTO] {
        let data = try await executor.searchSpecies(
            pattern: "%\(keyword)%",
            limit: limit,
            offset: offset
        )
        return data.pokemon_v2_pokemonspecies.map(mapSpecies)
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetailDTO {
        let data = try await executor.pokemonDetail(id: id)
        guard let pokemon = data.pokemon_v2_pokemon_by_pk else {
            throw PokemonRemoteDataSourceError.noData
        }
        return mapDetail(pokemon)
    }

    private func mapSpecies(
        _ species: PokemonAPI.SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy
    ) -> PokemonSpeciesDTO {
        PokemonSpeciesDTO(
            id: species.id,
            name: species.name,
            captureRate: species.capture_rate,
            color: species.pokemon_v2_pokemoncolor.map {
                PokemonColorDTO(id: $0.id, name: $0.name)
            },
            pokemons: species.pokemon_v2_pokemons.map {
                PokemonDTO(
                    id: $0.id,
                    name: $0.name,
                    abilityNames: $0.pokemon_v2_pokemonabilities.compactMap {
                        $0.pokemon_v2_ability?.name
                    }
                )
            }
        )
    }

    private func mapDetail(
        _ pokemon: PokemonAPI.PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk
    ) -> PokemonDetailDTO {
        PokemonDetailDTO(
            id: pokemon.id,
            name: pokemon.name,
            abilityNames: pokemon.pokemon_v2_pokemonabilities.compactMap {
                $0.pokemon_v2_ability?.name
            },
            typeNames: pokemon.pokemon_v2_pokemontypes.compactMap {
                $0.pokemon_v2_type?.name
            },
            height: pokemon.height,
            weight: pokemon.weight,
            captureRate: pokemon.pokemon_v2_pokemonspecy?.capture_rate,
            colorName: pokemon.pokemon_v2_pokemonspecy?.pokemon_v2_pokemoncolor?.name
        )
    }
}
