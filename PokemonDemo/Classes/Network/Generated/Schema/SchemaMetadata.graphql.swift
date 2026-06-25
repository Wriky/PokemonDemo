// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol PokemonAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == PokemonAPI.SchemaMetadata {}

nonisolated protocol PokemonAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == PokemonAPI.SchemaMetadata {}

nonisolated protocol PokemonAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == PokemonAPI.SchemaMetadata {}

nonisolated protocol PokemonAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == PokemonAPI.SchemaMetadata {}

extension PokemonAPI {
  typealias SelectionSet = PokemonAPI_SelectionSet

  typealias InlineFragment = PokemonAPI_InlineFragment

  typealias MutableSelectionSet = PokemonAPI_MutableSelectionSet

  typealias MutableInlineFragment = PokemonAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "pokemon_v2_ability": PokemonAPI.Objects.Pokemon_v2_ability,
      "pokemon_v2_pokemon": PokemonAPI.Objects.Pokemon_v2_pokemon,
      "pokemon_v2_pokemonability": PokemonAPI.Objects.Pokemon_v2_pokemonability,
      "pokemon_v2_pokemoncolor": PokemonAPI.Objects.Pokemon_v2_pokemoncolor,
      "pokemon_v2_pokemonspecies": PokemonAPI.Objects.Pokemon_v2_pokemonspecies,
      "pokemon_v2_pokemontype": PokemonAPI.Objects.Pokemon_v2_pokemontype,
      "pokemon_v2_type": PokemonAPI.Objects.Pokemon_v2_type,
      "query_root": PokemonAPI.Objects.Query_root
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}