//
//  ApolloClientProvider.swift
//  PokemonDemo
//

import Apollo
import Foundation

enum ApolloClientProvider {
    static let shared = ApolloClient(
        url: URL(string: "https://beta.pokeapi.co/graphql/v1beta")!
    )
}
