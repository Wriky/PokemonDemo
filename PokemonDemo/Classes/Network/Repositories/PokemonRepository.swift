import Foundation

nonisolated struct PokemonRepository: PokemonRepositoryProtocol {
    private let dataSource: any PokemonRemoteDataSourceProtocol

    init(dataSource: any PokemonRemoteDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        do {
            let dtos = try await dataSource.searchSpecies(
                keyword: keyword,
                limit: limit,
                offset: offset
            )
            return try dtos.map(PokemonMapper.mapSpecies)
        } catch {
            throw translate(error)
        }
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetail {
        do {
            let dto = try await dataSource.pokemonDetail(id: id)
            return try PokemonMapper.mapDetail(dto)
        } catch {
            throw translate(error)
        }
    }

    private func translate(_ error: Error) -> PokemonRepositoryError {
        switch error {
        case PokemonRemoteDataSourceError.noData:
            return .noData
        case let PokemonRemoteDataSourceError.graphQL(message):
            return .server(message)
        case PokemonRemoteDataSourceError.transport:
            return .unavailable
        case is PokemonMappingError:
            return .invalidData
        case let repositoryError as PokemonRepositoryError:
            return repositoryError
        default:
            return .unavailable
        }
    }
}

extension PokemonRepository {
    static var production: PokemonRepository {
        PokemonRepository(dataSource: ApolloPokemonRemoteDataSource())
    }
}
