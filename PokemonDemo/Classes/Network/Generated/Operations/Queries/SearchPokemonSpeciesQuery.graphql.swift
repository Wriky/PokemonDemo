// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension PokemonAPI {
  nonisolated struct SearchPokemonSpeciesQuery: GraphQLQuery {
    static let operationName: String = "SearchPokemonSpecies"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchPokemonSpecies($pattern: String!, $limit: Int!, $offset: Int!) { pokemon_v2_pokemonspecies( where: { name: { _ilike: $pattern } } limit: $limit offset: $offset order_by: { id: asc } ) { __typename id name capture_rate pokemon_v2_pokemoncolor { __typename id name } pokemon_v2_pokemons(order_by: { id: asc }) { __typename id name pokemon_v2_pokemonabilities(order_by: { id: asc }) { __typename id pokemon_v2_ability { __typename name } } } } }"#
      ))

    public var pattern: String
    public var limit: Int32
    public var offset: Int32

    public init(
      pattern: String,
      limit: Int32,
      offset: Int32
    ) {
      self.pattern = pattern
      self.limit = limit
      self.offset = offset
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "pattern": pattern,
      "limit": limit,
      "offset": offset
    ] }

    nonisolated struct Data: PokemonAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Query_root }
      static var __selections: [ApolloAPI.Selection] { [
        .field("pokemon_v2_pokemonspecies", [Pokemon_v2_pokemonspecy].self, arguments: [
          "where": ["name": ["_ilike": .variable("pattern")]],
          "limit": .variable("limit"),
          "offset": .variable("offset"),
          "order_by": ["id": "asc"]
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchPokemonSpeciesQuery.Data.self
      ] }

      /// An array relationship
      var pokemon_v2_pokemonspecies: [Pokemon_v2_pokemonspecy] { __data["pokemon_v2_pokemonspecies"] }

      /// Pokemon_v2_pokemonspecy
      ///
      /// Parent Type: `Pokemon_v2_pokemonspecies`
      nonisolated struct Pokemon_v2_pokemonspecy: PokemonAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemonspecies }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
          .field("capture_rate", Int?.self),
          .field("pokemon_v2_pokemoncolor", Pokemon_v2_pokemoncolor?.self),
          .field("pokemon_v2_pokemons", [Pokemon_v2_pokemon].self, arguments: ["order_by": ["id": "asc"]]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.self
        ] }

        var id: Int { __data["id"] }
        var name: String { __data["name"] }
        var capture_rate: Int? { __data["capture_rate"] }
        /// An object relationship
        var pokemon_v2_pokemoncolor: Pokemon_v2_pokemoncolor? { __data["pokemon_v2_pokemoncolor"] }
        /// An array relationship
        var pokemon_v2_pokemons: [Pokemon_v2_pokemon] { __data["pokemon_v2_pokemons"] }

        /// Pokemon_v2_pokemonspecy.Pokemon_v2_pokemoncolor
        ///
        /// Parent Type: `Pokemon_v2_pokemoncolor`
        nonisolated struct Pokemon_v2_pokemoncolor: PokemonAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemoncolor }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemoncolor.self
          ] }

          var id: Int { __data["id"] }
          var name: String { __data["name"] }
        }

        /// Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon
        ///
        /// Parent Type: `Pokemon_v2_pokemon`
        nonisolated struct Pokemon_v2_pokemon: PokemonAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemon }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("name", String.self),
            .field("pokemon_v2_pokemonabilities", [Pokemon_v2_pokemonability].self, arguments: ["order_by": ["id": "asc"]]),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon.self
          ] }

          var id: Int { __data["id"] }
          var name: String { __data["name"] }
          /// An array relationship
          var pokemon_v2_pokemonabilities: [Pokemon_v2_pokemonability] { __data["pokemon_v2_pokemonabilities"] }

          /// Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon.Pokemon_v2_pokemonability
          ///
          /// Parent Type: `Pokemon_v2_pokemonability`
          nonisolated struct Pokemon_v2_pokemonability: PokemonAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemonability }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", Int.self),
              .field("pokemon_v2_ability", Pokemon_v2_ability?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon.Pokemon_v2_pokemonability.self
            ] }

            var id: Int { __data["id"] }
            /// An object relationship
            var pokemon_v2_ability: Pokemon_v2_ability? { __data["pokemon_v2_ability"] }

            /// Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon.Pokemon_v2_pokemonability.Pokemon_v2_ability
            ///
            /// Parent Type: `Pokemon_v2_ability`
            nonisolated struct Pokemon_v2_ability: PokemonAPI.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_ability }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("name", String.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                SearchPokemonSpeciesQuery.Data.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemon.Pokemon_v2_pokemonability.Pokemon_v2_ability.self
              ] }

              var name: String { __data["name"] }
            }
          }
        }
      }
    }
  }

}