//
//  PokemonRepositoryProtocol.swift
//  PokemonDemo
//

import Foundation

nonisolated protocol PokemonRepositoryProtocol: Sendable {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies]
    func pokemonDetail(id: Int) async throws -> PokemonDetail
}

nonisolated enum PokemonRepositoryError: LocalizedError, Equatable, Sendable {
    case noData
    case unavailable
    case invalidData
    case server(String)

    var errorDescription: String? {
        switch self {
        case .noData:
            return "The server returned no usable Pokemon data."
        case .unavailable:
            return "Pokemon data is currently unavailable. Please try again."
        case .invalidData:
            return "The server returned invalid Pokemon data."
        case let .server(message):
            return message
        }
    }
}
