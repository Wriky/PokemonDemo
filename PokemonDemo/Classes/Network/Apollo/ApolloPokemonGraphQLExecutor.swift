import Apollo
import ApolloAPI
import Foundation

actor ApolloPokemonGraphQLExecutor: PokemonGraphQLExecuting {
    private let client: ApolloClient

    init(client: ApolloClient = ApolloClientProvider.shared) {
        self.client = client
    }

    func searchSpecies(
        pattern: String,
        limit: Int,
        offset: Int
    ) async throws -> PokemonAPI.SearchPokemonSpeciesQuery.Data {
        guard let limit = Int32(exactly: limit),
              let offset = Int32(exactly: offset) else {
            throw PokemonRemoteDataSourceError.transport("Invalid search pagination.")
        }

        return try await fetch(
            PokemonAPI.SearchPokemonSpeciesQuery(
                pattern: pattern,
                limit: limit,
                offset: offset
            )
        )
    }

    func pokemonDetail(id: Int) async throws -> PokemonAPI.PokemonDetailQuery.Data {
        guard let id = Int32(exactly: id) else {
            throw PokemonRemoteDataSourceError.transport("Invalid Pokemon identifier.")
        }
        return try await fetch(PokemonAPI.PokemonDetailQuery(id: id))
    }

    private func fetch<Query: GraphQLQuery>(
        _ query: Query
    ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
        do {
            var finalResponse: GraphQLResponse<Query>?
            for try await response in try client.fetch(
                query: query,
                cachePolicy: .cacheAndNetwork
            ) {
                finalResponse = response
            }

            guard let finalResponse else {
                throw PokemonRemoteDataSourceError.noData
            }
            if let message = finalResponse.errors?.first?.message {
                throw PokemonRemoteDataSourceError.graphQL(message)
            }
            guard let data = finalResponse.data else {
                throw PokemonRemoteDataSourceError.noData
            }
            return data
        } catch let error as PokemonRemoteDataSourceError {
            throw error
        } catch {
            throw PokemonRemoteDataSourceError.transport(
                "Unable to connect to the Pokemon service."
            )
        }
    }
}
