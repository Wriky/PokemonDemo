//
//  PokemonService.swift
//  PokemonDemo
//
//  Created by Riky Wang on 2026/5/20.
//

import Foundation

protocol PokemonServicing {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies]
}

struct PokemonService: PokemonServicing {
    private let endpoint = URL(string: "https://beta.pokeapi.co/graphql/v1beta")!
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        let requestBody = GraphQLRequest(
            query: PokemonGraphQLQuery.searchSpecies,
            variables: [
                "pattern": "%\(keyword)%",
                "limit": limit,
                "offset": offset
            ]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PokemonServiceError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(GraphQLResponse.self, from: data)

        if let errors = decoded.errors, let firstMessage = errors.first?.message {
            throw PokemonServiceError.serverError(firstMessage)
        }

        guard let data = decoded.data else {
            throw PokemonServiceError.invalidData
        }

        return data.pokemonSpecies
    }
}

private enum PokemonGraphQLQuery {
    static let searchSpecies = """
    query SearchPokemonSpecies($pattern: String!, $limit: Int!, $offset: Int!) {
      pokemon_v2_pokemonspecies(
        where: {name: {_ilike: $pattern}}
        limit: $limit
        offset: $offset
        order_by: {id: asc}
      ) {
        id
        name
        capture_rate
        pokemon_v2_pokemoncolor {
          id
          name
        }
        pokemon_v2_pokemons(order_by: {id: asc}) {
          id
          name
          pokemon_v2_pokemonabilities(order_by: {id: asc}) {
            id
            pokemon_v2_ability {
              name
            }
          }
        }
      }
    }
    """
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: GraphQLValue]

    nonisolated init(query: String, variables: [String: Any]) {
        self.query = query
        self.variables = variables.mapValues(GraphQLValue.init)
    }
}

private enum GraphQLValue: Encodable {
    case string(String)
    case int(Int)

    nonisolated init(_ value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let int as Int:
            self = .int(int)
        default:
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .string(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        }
    }
}

private struct GraphQLResponse: Decodable {
    let data: GraphQLData?
    let errors: [GraphQLError]?
}

private struct GraphQLData: Decodable {
    let pokemonSpecies: [PokemonSpecies]

    enum CodingKeys: String, CodingKey {
        case pokemonSpecies = "pokemon_v2_pokemonspecies"
    }
}

private struct GraphQLError: Decodable {
    let message: String
}

enum PokemonServiceError: LocalizedError {
    case invalidResponse
    case invalidData
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server response was invalid."
        case .invalidData:
            return "The server returned no usable Pokemon data."
        case let .serverError(message):
            return message
        }
    }
}
