//
//  PokemonRepositoryProtocol.swift
//  PokemonDemo
//

import Foundation

protocol PokemonRepositoryProtocol: Sendable {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies]
    func pokemonDetail(id: Int) async throws -> PokemonDetail
}

enum PokemonRepositoryError: LocalizedError, Equatable {
    case noData
    case graphQL(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .noData:
            return "The server returned no usable Pokemon data."
        case let .graphQL(message), let .transport(message):
            return message
        }
    }
}
