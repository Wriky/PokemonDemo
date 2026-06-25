//
//  ApolloClientProvider.swift
//  PokemonDemo
//

import Apollo
import Foundation

nonisolated enum PokemonAPIConfiguration {
    static var endpoint: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "beta.pokeapi.co"
        components.path = "/graphql/v1beta"
        return components.url
            ?? URL(fileURLWithPath: "/invalid-pokemon-api-endpoint")
    }
}

nonisolated enum ApolloClientProvider {
    static let shared = makeClient()

    static func makeClient() -> ApolloClient {
        ApolloClient(url: PokemonAPIConfiguration.endpoint)
    }
}
