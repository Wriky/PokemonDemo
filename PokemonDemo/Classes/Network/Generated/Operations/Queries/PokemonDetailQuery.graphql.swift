// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension PokemonAPI {
  nonisolated struct PokemonDetailQuery: GraphQLQuery {
    static let operationName: String = "PokemonDetail"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query PokemonDetail($id: Int!) { pokemon_v2_pokemon_by_pk(id: $id) { __typename id name height weight pokemon_v2_pokemonabilities(order_by: { id: asc }) { __typename id pokemon_v2_ability { __typename name } } pokemon_v2_pokemontypes(order_by: { slot: asc }) { __typename pokemon_v2_type { __typename name } } pokemon_v2_pokemonspecy { __typename capture_rate pokemon_v2_pokemoncolor { __typename name } } } }"#
      ))

    public var id: Int32

    public init(id: Int32) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    nonisolated struct Data: PokemonAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Query_root }
      static var __selections: [ApolloAPI.Selection] { [
        .field("pokemon_v2_pokemon_by_pk", Pokemon_v2_pokemon_by_pk?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PokemonDetailQuery.Data.self
      ] }

      /// fetch data from the table: "pokemon_v2_pokemon" using primary key columns
      var pokemon_v2_pokemon_by_pk: Pokemon_v2_pokemon_by_pk? { __data["pokemon_v2_pokemon_by_pk"] }

      /// Pokemon_v2_pokemon_by_pk
      ///
      /// Parent Type: `Pokemon_v2_pokemon`
      nonisolated struct Pokemon_v2_pokemon_by_pk: PokemonAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemon }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("name", String.self),
          .field("height", Int?.self),
          .field("weight", Int?.self),
          .field("pokemon_v2_pokemonabilities", [Pokemon_v2_pokemonability].self, arguments: ["order_by": ["id": "asc"]]),
          .field("pokemon_v2_pokemontypes", [Pokemon_v2_pokemontype].self, arguments: ["order_by": ["slot": "asc"]]),
          .field("pokemon_v2_pokemonspecy", Pokemon_v2_pokemonspecy?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.self
        ] }

        var id: Int { __data["id"] }
        var name: String { __data["name"] }
        var height: Int? { __data["height"] }
        var weight: Int? { __data["weight"] }
        /// An array relationship
        var pokemon_v2_pokemonabilities: [Pokemon_v2_pokemonability] { __data["pokemon_v2_pokemonabilities"] }
        /// An array relationship
        var pokemon_v2_pokemontypes: [Pokemon_v2_pokemontype] { __data["pokemon_v2_pokemontypes"] }
        /// An object relationship
        var pokemon_v2_pokemonspecy: Pokemon_v2_pokemonspecy? { __data["pokemon_v2_pokemonspecy"] }

        /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonability
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
            PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonability.self
          ] }

          var id: Int { __data["id"] }
          /// An object relationship
          var pokemon_v2_ability: Pokemon_v2_ability? { __data["pokemon_v2_ability"] }

          /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonability.Pokemon_v2_ability
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
              PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonability.Pokemon_v2_ability.self
            ] }

            var name: String { __data["name"] }
          }
        }

        /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemontype
        ///
        /// Parent Type: `Pokemon_v2_pokemontype`
        nonisolated struct Pokemon_v2_pokemontype: PokemonAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemontype }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("pokemon_v2_type", Pokemon_v2_type?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemontype.self
          ] }

          /// An object relationship
          var pokemon_v2_type: Pokemon_v2_type? { __data["pokemon_v2_type"] }

          /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemontype.Pokemon_v2_type
          ///
          /// Parent Type: `Pokemon_v2_type`
          nonisolated struct Pokemon_v2_type: PokemonAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_type }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemontype.Pokemon_v2_type.self
            ] }

            var name: String { __data["name"] }
          }
        }

        /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonspecy
        ///
        /// Parent Type: `Pokemon_v2_pokemonspecies`
        nonisolated struct Pokemon_v2_pokemonspecy: PokemonAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemonspecies }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("capture_rate", Int?.self),
            .field("pokemon_v2_pokemoncolor", Pokemon_v2_pokemoncolor?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonspecy.self
          ] }

          var capture_rate: Int? { __data["capture_rate"] }
          /// An object relationship
          var pokemon_v2_pokemoncolor: Pokemon_v2_pokemoncolor? { __data["pokemon_v2_pokemoncolor"] }

          /// Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemoncolor
          ///
          /// Parent Type: `Pokemon_v2_pokemoncolor`
          nonisolated struct Pokemon_v2_pokemoncolor: PokemonAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { PokemonAPI.Objects.Pokemon_v2_pokemoncolor }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PokemonDetailQuery.Data.Pokemon_v2_pokemon_by_pk.Pokemon_v2_pokemonspecy.Pokemon_v2_pokemoncolor.self
            ] }

            var name: String { __data["name"] }
          }
        }
      }
    }
  }

}