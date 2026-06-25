import XCTest
import Apollo
import UIKit
@_spi(Unsafe) import ApolloAPI
@testable import PokemonDemo

final class PokemonDemoTests: XCTestCase {
    func testSearchPresentationUsesSingularFormHint() {
        XCTAssertEqual(
            PokemonSearchPresentation.formHint(count: 1),
            "1 discovered form"
        )
    }

    func testSearchPresentationUsesPluralFormHint() {
        XCTAssertEqual(
            PokemonSearchPresentation.formHint(count: 3),
            "3 discovered forms"
        )
    }

    func testSearchPresentationFormatsMissingCaptureRateAsUnknown() {
        XCTAssertEqual(PokemonSearchPresentation.captureRate(nil), "—")
        XCTAssertEqual(PokemonSearchPresentation.captureRate(45), "45")
    }

    func testPokemonMapperMapsSpeciesAndNormalizesAbilityNames() throws {
        let dto = PokemonSpeciesDTO(
            id: 25,
            name: " pikachu ",
            captureRate: 190,
            color: PokemonColorDTO(id: 10, name: " yellow "),
            pokemons: [
                PokemonDTO(
                    id: 25,
                    name: " pikachu ",
                    abilityNames: [" static ", "", "static", " lightning-rod "]
                )
            ]
        )

        let species = try PokemonMapper.mapSpecies(dto)

        XCTAssertEqual(species.name, "pikachu")
        XCTAssertEqual(species.color?.name, "yellow")
        XCTAssertEqual(species.pokemons.first?.abilityNames, ["static", "lightning-rod"])
    }

    func testPokemonMapperMapsDetailAndNormalizesTypes() throws {
        let dto = PokemonDetailDTO(
            id: 25,
            name: " pikachu ",
            abilityNames: [" static ", "static"],
            typeNames: [" electric ", "", "electric"],
            height: 4,
            weight: 60,
            captureRate: 190,
            colorName: " yellow "
        )

        let detail = try PokemonMapper.mapDetail(dto)

        XCTAssertEqual(detail.name, "pikachu")
        XCTAssertEqual(detail.abilityNames, ["static"])
        XCTAssertEqual(detail.typeNames, ["electric"])
        XCTAssertEqual(detail.colorName, "yellow")
    }

    func testPokemonMapperRejectsInvalidRequiredValues() {
        let invalidSpecies = PokemonSpeciesDTO(
            id: 0,
            name: " ",
            captureRate: nil,
            color: nil,
            pokemons: []
        )

        XCTAssertThrowsError(try PokemonMapper.mapSpecies(invalidSpecies)) { error in
            XCTAssertEqual(error as? PokemonMappingError, .invalidIdentifier)
        }
    }

    func testPokemonRepositoryForwardsSearchArgumentsAndMapsDTOs() async throws {
        let dataSource = PokemonRemoteDataSourceFake(
            searchResult: .success([
                PokemonSpeciesDTO(
                    id: 25,
                    name: "pikachu",
                    captureRate: 190,
                    color: nil,
                    pokemons: []
                )
            ])
        )
        let repository = PokemonRepository(dataSource: dataSource)

        let species = try await repository.searchSpecies(
            keyword: "pika",
            limit: 20,
            offset: 40
        )

        XCTAssertEqual(species.map(\.name), ["pikachu"])
        let request = await dataSource.lastSearchRequest
        XCTAssertEqual(request, .init(keyword: "pika", limit: 20, offset: 40))
    }

    func testPokemonRepositoryForwardsDetailIDAndMapsDTO() async throws {
        let dataSource = PokemonRemoteDataSourceFake(
            detailResult: .success(
                PokemonDetailDTO(
                    id: 25,
                    name: "pikachu",
                    abilityNames: ["static"],
                    typeNames: ["electric"],
                    height: 4,
                    weight: 60,
                    captureRate: 190,
                    colorName: "yellow"
                )
            )
        )
        let repository = PokemonRepository(dataSource: dataSource)

        let detail = try await repository.pokemonDetail(id: 25)

        XCTAssertEqual(detail.name, "pikachu")
        let detailID = await dataSource.lastDetailID
        XCTAssertEqual(detailID, 25)
    }

    func testPokemonRepositoryTranslatesRemoteErrors() async {
        let cases: [(PokemonRemoteDataSourceError, PokemonRepositoryError)] = [
            (.noData, .noData),
            (.graphQL("boom"), .server("boom")),
            (.transport("offline"), .unavailable)
        ]

        for (remoteError, expectedError) in cases {
            let repository = PokemonRepository(
                dataSource: PokemonRemoteDataSourceFake(
                    searchResult: .failure(remoteError)
                )
            )

            do {
                _ = try await repository.searchSpecies(keyword: "pika", limit: 20, offset: 0)
                XCTFail("Expected \(expectedError)")
            } catch {
                XCTAssertEqual(error as? PokemonRepositoryError, expectedError)
            }
        }
    }

    func testPokemonRepositoryTranslatesMappingFailure() async {
        let repository = PokemonRepository(
            dataSource: PokemonRemoteDataSourceFake(
                searchResult: .success([
                    PokemonSpeciesDTO(
                        id: 0,
                        name: "",
                        captureRate: nil,
                        color: nil,
                        pokemons: []
                    )
                ])
            )
        )

        do {
            _ = try await repository.searchSpecies(keyword: "pika", limit: 20, offset: 0)
            XCTFail("Expected invalidData")
        } catch {
            XCTAssertEqual(error as? PokemonRepositoryError, .invalidData)
        }
    }

    func testApolloRemoteDataSourceWrapsKeywordAndMapsSearchData() async throws {
        let executor = PokemonGraphQLExecutorFake(
            searchResult: .success(makeSearchData())
        )
        let dataSource = ApolloPokemonRemoteDataSource(executor: executor)

        let species = try await dataSource.searchSpecies(
            keyword: "pika",
            limit: 20,
            offset: 40
        )

        let request = await executor.lastSearchRequest
        XCTAssertEqual(request, .init(pattern: "%pika%", limit: 20, offset: 40))
        XCTAssertEqual(species.first?.name, "pikachu")
        XCTAssertEqual(species.first?.pokemons.first?.abilityNames, ["static"])
    }

    func testApolloRemoteDataSourceForwardsDetailIDAndMapsData() async throws {
        let executor = PokemonGraphQLExecutorFake(
            detailResult: .success(makeDetailData())
        )
        let dataSource = ApolloPokemonRemoteDataSource(executor: executor)

        let detail = try await dataSource.pokemonDetail(id: 25)

        let detailID = await executor.lastDetailID
        XCTAssertEqual(detailID, 25)
        XCTAssertEqual(detail.name, "pikachu")
        XCTAssertEqual(detail.typeNames, ["electric"])
        XCTAssertEqual(detail.colorName, "yellow")
    }

    func testApolloRemoteDataSourceRejectsMissingDetail() async {
        let executor = PokemonGraphQLExecutorFake(
            detailResult: .success(makeDetailData(includePokemon: false))
        )
        let dataSource = ApolloPokemonRemoteDataSource(executor: executor)

        do {
            _ = try await dataSource.pokemonDetail(id: 25)
            XCTFail("Expected noData")
        } catch {
            XCTAssertEqual(error as? PokemonRemoteDataSourceError, .noData)
        }
    }

    func testApolloExecutorUsesFinalCacheAndNetworkResponse() async throws {
        let transport = GraphQLNetworkTransportFake { query in
            guard query is PokemonAPI.SearchPokemonSpeciesQuery else {
                throw PokemonRemoteDataSourceError.transport("Unexpected query")
            }
            return [
                GraphQLResponse<PokemonAPI.SearchPokemonSpeciesQuery>(
                    data: makeSearchData(speciesName: "cached"),
                    extensions: nil,
                    errors: nil,
                    source: .cache,
                    dependentKeys: nil
                ),
                GraphQLResponse<PokemonAPI.SearchPokemonSpeciesQuery>(
                    data: makeSearchData(speciesName: "network"),
                    extensions: nil,
                    errors: nil,
                    source: .server,
                    dependentKeys: nil
                )
            ]
        }
        let client = ApolloClient(
            networkTransport: transport,
            store: ApolloStore(cache: InMemoryNormalizedCache())
        )
        let executor = ApolloPokemonGraphQLExecutor(client: client)

        let data = try await executor.searchSpecies(pattern: "%pika%", limit: 20, offset: 0)

        XCTAssertEqual(data.pokemon_v2_pokemonspecies.first?.name, "network")
    }

    func testApolloExecutorTranslatesGraphQLError() async {
        let transport = GraphQLNetworkTransportFake { _ in
            [
                GraphQLResponse<PokemonAPI.SearchPokemonSpeciesQuery>(
                    data: nil,
                    extensions: nil,
                    errors: [GraphQLError(["message": "boom"])],
                    source: .server,
                    dependentKeys: nil
                )
            ]
        }
        let executor = ApolloPokemonGraphQLExecutor(
            client: ApolloClient(
                networkTransport: transport,
                store: ApolloStore(cache: InMemoryNormalizedCache())
            )
        )

        do {
            _ = try await executor.searchSpecies(pattern: "%pika%", limit: 20, offset: 0)
            XCTFail("Expected GraphQL error")
        } catch {
            XCTAssertEqual(error as? PokemonRemoteDataSourceError, .graphQL("boom"))
        }
    }

    func testApolloExecutorTranslatesTransportError() async {
        let transport = GraphQLNetworkTransportFake { _ in
            throw URLError(.notConnectedToInternet)
        }
        let executor = ApolloPokemonGraphQLExecutor(
            client: ApolloClient(
                networkTransport: transport,
                store: ApolloStore(cache: InMemoryNormalizedCache())
            )
        )

        do {
            _ = try await executor.pokemonDetail(id: 25)
            XCTFail("Expected transport error")
        } catch {
            XCTAssertEqual(
                error as? PokemonRemoteDataSourceError,
                .transport("Unable to connect to the Pokemon service.")
            )
        }
    }

    func testHomeViewModelReadsAndWritesInjectedDefaults() {
        let suiteName = "PokemonDemoTests.Home.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = HomeViewModel(defaults: defaults)

        XCTAssertFalse(viewModel.hasSeenWelcome)

        viewModel.completeWelcome()

        XCTAssertTrue(viewModel.hasSeenWelcome)
    }

    func testSearchDebouncerOnlyRunsLatestScheduledAction() async {
        let debouncer = SearchDebouncer(delay: .zero)
        let actionCompleted = AsyncGate()
        var executedValues: [Int] = []

        debouncer.schedule {
            executedValues.append(1)
        }
        debouncer.schedule {
            executedValues.append(2)
            actionCompleted.open()
        }

        await actionCompleted.wait()

        XCTAssertEqual(executedValues, [2])
    }

    func testDebouncerCancelDoesNotCancelActionAfterDelayEnds() async {
        let debouncer = SearchDebouncer(delay: .zero)
        let actionStarted = AsyncGate()
        let allowActionToFinish = AsyncGate()
        let actionCompleted = AsyncGate()
        var actionWasCancelled: Bool?

        debouncer.schedule {
            actionStarted.open()
            await allowActionToFinish.wait()
            actionWasCancelled = Task.isCancelled
            actionCompleted.open()
        }

        await actionStarted.wait()
        debouncer.cancel()
        allowActionToFinish.open()
        await actionCompleted.wait()

        XCTAssertEqual(actionWasCancelled, false)
    }

    func testNewerSearchResultWinsWhenOlderRequestFinishesLast() async {
        let repository = ControlledPokemonRepository()
        let viewModel = SearchViewModel(repository: repository)

        viewModel.keyword = "old"
        let oldSearch = Task {
            await viewModel.search()
        }

        await repository.waitForRequest(keyword: "old", offset: 0)

        viewModel.keyword = "new"
        let newSearch = Task {
            await viewModel.search()
        }

        await repository.waitForRequest(keyword: "new", offset: 0)
        await repository.complete(
            keyword: "new",
            offset: 0,
            with: [makeSpecies(id: 2, name: "new")]
        )
        await repository.complete(
            keyword: "old",
            offset: 0,
            with: [makeSpecies(id: 1, name: "old")]
        )

        await oldSearch.value
        await newSearch.value

        XCTAssertEqual(viewModel.speciesList.map(\.name), ["new"])
    }

    func testOldPaginationResponseCannotMutateNewSearchState() async {
        let repository = ControlledPokemonRepository()
        let viewModel = SearchViewModel(repository: repository)

        viewModel.keyword = "old"
        let initialSearch = Task {
            await viewModel.search()
        }
        await repository.waitForRequest(keyword: "old", offset: 0)
        await repository.complete(
            keyword: "old",
            offset: 0,
            with: makeSpeciesPage(prefix: "old", startID: 1, count: 20)
        )
        await initialSearch.value

        let oldPagination = Task {
            await viewModel.loadMore()
        }
        await repository.waitForRequest(keyword: "old", offset: 20)

        viewModel.keyword = "new"
        let newSearch = Task {
            await viewModel.search()
        }
        await repository.waitForRequest(keyword: "new", offset: 0)
        await repository.complete(
            keyword: "new",
            offset: 0,
            with: makeSpeciesPage(prefix: "new", startID: 101, count: 20)
        )
        await newSearch.value

        await repository.complete(
            keyword: "old",
            offset: 20,
            with: [makeSpecies(id: 21, name: "stale-page")]
        )
        await oldPagination.value

        XCTAssertEqual(viewModel.speciesList.map(\.name), (0..<20).map { "new-\($0)" })
        XCTAssertTrue(viewModel.shouldShowLoadMore)
        guard viewModel.shouldShowLoadMore else { return }

        let newPagination = Task {
            await viewModel.loadMore()
        }
        await repository.waitForRequest(keyword: "new", offset: 20)
        await repository.complete(keyword: "new", offset: 20, with: [])
        await newPagination.value
    }

    func testPaginationCallsOffsetsZeroThenTwenty() async {
        let repository = ControlledPokemonRepository()
        let viewModel = SearchViewModel(repository: repository)

        viewModel.keyword = "pika"
        let initialSearch = Task {
            await viewModel.search()
        }
        await repository.waitForRequest(keyword: "pika", offset: 0)
        await repository.complete(
            keyword: "pika",
            offset: 0,
            with: makeSpeciesPage(prefix: "pika", startID: 1, count: 20)
        )
        await initialSearch.value

        let pagination = Task {
            await viewModel.loadMore()
        }
        await repository.waitForRequest(keyword: "pika", offset: 20)
        await repository.complete(keyword: "pika", offset: 20, with: [])
        await pagination.value

        let offsets = await repository.requestedOffsets
        XCTAssertEqual(offsets, [0, 20])
    }

    func testArtworkURLBuilderReturnsOrderedFallbacksForPokemonID() {
        let urls = PokemonArtworkURLBuilder.urls(for: 25).map(\.absoluteString)

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(
            urls[0],
            "https://cdn.jsdelivr.net/gh/PokeAPI/sprites@master/sprites/pokemon/other/official-artwork/25.png"
        )
        XCTAssertTrue(urls[1].hasSuffix("/sprites/pokemon/25.png"))
        XCTAssertTrue(urls[2].hasSuffix("/sprites/pokemon/other/home/25.png"))
        XCTAssertTrue(urls.allSatisfy { $0.contains("25.png") })
    }

    func testArtworkLoaderStopsAfterFirstSuccessfulFallback() async {
        let urls = PokemonArtworkURLBuilder.urls(for: 25)
        var attemptedURLs: [URL] = []
        let expectedImage = UIImage(systemName: "star.fill")

        let image = await PokemonArtworkLoader.loadFirstAvailableImage(from: urls) { url in
            attemptedURLs.append(url)
            return url == urls[1] ? expectedImage : nil
        }

        XCTAssertNotNil(image)
        XCTAssertEqual(attemptedURLs, Array(urls.prefix(2)))
    }

    func testDetailViewModelLoadsIndependentDetail() async {
        let repository = PokemonRepositoryFake(
            detailResult: .success(.fixture(name: "pikachu"))
        )
        let viewModel = PokemonDetailViewModel(
            pokemonID: 25,
            placeholderName: "Pikachu",
            repository: repository
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.detail?.name, "pikachu")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDetailViewModelRetriesAfterFailure() async {
        let repository = PokemonRepositoryFake(
            detailResults: [
                .failure(PokemonRepositoryError.server("boom")),
                .success(.fixture(name: "pikachu"))
            ]
        )
        let viewModel = PokemonDetailViewModel(
            pokemonID: 25,
            placeholderName: "Pikachu",
            repository: repository
        )

        await viewModel.load()
        XCTAssertEqual(viewModel.errorMessage, "boom")
        XCTAssertNil(viewModel.detail)

        await viewModel.load()
        XCTAssertEqual(viewModel.detail?.name, "pikachu")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRepositoryErrorDescriptions() {
        XCTAssertEqual(
            PokemonRepositoryError.server("boom").errorDescription,
            "boom"
        )
        XCTAssertEqual(
            PokemonRepositoryError.noData.errorDescription,
            "The server returned no usable Pokemon data."
        )
    }
}

nonisolated private final class GraphQLNetworkTransportFake: NetworkTransport, @unchecked Sendable {
    private let handler: (Any) throws -> Any

    init(handler: @escaping (Any) throws -> Any) {
        self.handler = handler
    }

    func send<Query: GraphQLQuery>(
        query: Query,
        fetchBehavior: FetchBehavior,
        requestConfiguration: RequestConfiguration
    ) throws -> AsyncThrowingStream<GraphQLResponse<Query>, any Error> {
        let responses = try handler(query) as! [GraphQLResponse<Query>]
        return AsyncThrowingStream<GraphQLResponse<Query>, any Error> {
            (continuation: AsyncThrowingStream<GraphQLResponse<Query>, any Error>.Continuation) in
            for response in responses {
                continuation.yield(response)
            }
            continuation.finish()
        }
    }

    func send<Mutation: GraphQLMutation>(
        mutation: Mutation,
        requestConfiguration: RequestConfiguration
    ) throws -> AsyncThrowingStream<GraphQLResponse<Mutation>, any Error> {
        throw PokemonRemoteDataSourceError.transport("Mutations are unsupported in tests.")
    }
}

private actor PokemonGraphQLExecutorFake: PokemonGraphQLExecuting {
    struct SearchRequest: Equatable {
        let pattern: String
        let limit: Int
        let offset: Int
    }

    private let searchResult: Result<PokemonAPI.SearchPokemonSpeciesQuery.Data, Error>
    private let detailResult: Result<PokemonAPI.PokemonDetailQuery.Data, Error>
    private(set) var lastSearchRequest: SearchRequest?
    private(set) var lastDetailID: Int?

    init(
        searchResult: Result<PokemonAPI.SearchPokemonSpeciesQuery.Data, Error> = .success(makeSearchData(species: [])),
        detailResult: Result<PokemonAPI.PokemonDetailQuery.Data, Error> = .success(makeDetailData())
    ) {
        self.searchResult = searchResult
        self.detailResult = detailResult
    }

    func searchSpecies(
        pattern: String,
        limit: Int,
        offset: Int
    ) async throws -> PokemonAPI.SearchPokemonSpeciesQuery.Data {
        lastSearchRequest = SearchRequest(pattern: pattern, limit: limit, offset: offset)
        return try searchResult.get()
    }

    func pokemonDetail(id: Int) async throws -> PokemonAPI.PokemonDetailQuery.Data {
        lastDetailID = id
        return try detailResult.get()
    }
}

private actor PokemonRemoteDataSourceFake: PokemonRemoteDataSourceProtocol {
    struct SearchRequest: Equatable {
        let keyword: String
        let limit: Int
        let offset: Int
    }

    private let searchResult: Result<[PokemonSpeciesDTO], Error>
    private let detailResult: Result<PokemonDetailDTO, Error>
    private(set) var lastSearchRequest: SearchRequest?
    private(set) var lastDetailID: Int?

    init(
        searchResult: Result<[PokemonSpeciesDTO], Error> = .success([]),
        detailResult: Result<PokemonDetailDTO, Error> = .failure(PokemonRemoteDataSourceError.noData)
    ) {
        self.searchResult = searchResult
        self.detailResult = detailResult
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpeciesDTO] {
        lastSearchRequest = SearchRequest(keyword: keyword, limit: limit, offset: offset)
        return try searchResult.get()
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetailDTO {
        lastDetailID = id
        return try detailResult.get()
    }
}

private actor ControlledPokemonRepository: PokemonRepositoryProtocol {
    private struct RequestKey: Hashable {
        let keyword: String
        let offset: Int
    }

    private(set) var requestedOffsets: [Int] = []
    private var requests: Set<RequestKey> = []
    private var requestWaiters: [RequestKey: [CheckedContinuation<Void, Never>]] = [:]
    private var responseContinuations: [RequestKey: CheckedContinuation<[PokemonSpecies], Never>] = [:]

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        requestedOffsets.append(offset)
        let key = RequestKey(keyword: keyword, offset: offset)
        requests.insert(key)
        requestWaiters.removeValue(forKey: key)?.forEach { $0.resume() }

        return await withCheckedContinuation { continuation in
            responseContinuations[key] = continuation
        }
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetail {
        XCTFail("Detail should not be requested in search-only tests")
        throw PokemonRepositoryError.noData
    }

    func waitForRequest(keyword: String, offset: Int) async {
        let key = RequestKey(keyword: keyword, offset: offset)
        guard !requests.contains(key) else { return }

        await withCheckedContinuation { continuation in
            requestWaiters[key, default: []].append(continuation)
        }
    }

    func complete(keyword: String, offset: Int, with species: [PokemonSpecies]) {
        let key = RequestKey(keyword: keyword, offset: offset)
        responseContinuations.removeValue(forKey: key)?.resume(returning: species)
    }
}

private actor PokemonRepositoryFake: PokemonRepositoryProtocol {
    private var detailResults: [Result<PokemonDetail, Error>]

    init(detailResult: Result<PokemonDetail, Error>) {
        self.detailResults = [detailResult]
    }

    init(detailResults: [Result<PokemonDetail, Error>]) {
        self.detailResults = detailResults
    }

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        []
    }

    func pokemonDetail(id: Int) async throws -> PokemonDetail {
        guard !detailResults.isEmpty else {
            throw PokemonRepositoryError.noData
        }
        let result = detailResults.removeFirst()
        return try result.get()
    }
}

@MainActor
private final class AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

private func makeSpecies(id: Int, name: String) -> PokemonSpecies {
    PokemonSpecies(
        id: id,
        name: name,
        captureRate: 45,
        color: nil,
        pokemons: []
    )
}

private func makeSpeciesPage(prefix: String, startID: Int, count: Int) -> [PokemonSpecies] {
    (0..<count).map { index in
        makeSpecies(id: startID + index, name: "\(prefix)-\(index)")
    }
}

private extension PokemonDetail {
    static func fixture(name: String) -> PokemonDetail {
        PokemonDetail(
            id: 25,
            name: name,
            abilityNames: ["static"],
            typeNames: ["electric"],
            height: 4,
            weight: 60,
            captureRate: 190,
            colorName: "yellow"
        )
    }
}

nonisolated private func makeSearchData(
    species: [DataDict]? = nil,
    speciesName: String = "pikachu"
) -> PokemonAPI.SearchPokemonSpeciesQuery.Data {
    let ability = DataDict(
        data: [
            "__typename": "pokemon_v2_ability",
            "name": "static"
        ],
        fulfilledFragments: []
    )
    let pokemonAbility = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemonability",
            "id": 1,
            "pokemon_v2_ability": ability
        ],
        fulfilledFragments: []
    )
    let pokemon = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemon",
            "id": 25,
            "name": "pikachu",
            "pokemon_v2_pokemonabilities": [pokemonAbility]
        ],
        fulfilledFragments: []
    )
    let color = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemoncolor",
            "id": 10,
            "name": "yellow"
        ],
        fulfilledFragments: []
    )
    let defaultSpecies = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemonspecies",
            "id": 25,
            "name": speciesName,
            "capture_rate": 190,
            "pokemon_v2_pokemoncolor": color,
            "pokemon_v2_pokemons": [pokemon]
        ],
        fulfilledFragments: []
    )
    return PokemonAPI.SearchPokemonSpeciesQuery.Data(
        _dataDict: DataDict(
            data: ["pokemon_v2_pokemonspecies": species ?? [defaultSpecies]],
            fulfilledFragments: []
        )
    )
}

nonisolated private func makeDetailData(
    includePokemon: Bool = true
) -> PokemonAPI.PokemonDetailQuery.Data {
    let ability = DataDict(
        data: [
            "__typename": "pokemon_v2_ability",
            "name": "static"
        ],
        fulfilledFragments: []
    )
    let pokemonAbility = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemonability",
            "id": 1,
            "pokemon_v2_ability": ability
        ],
        fulfilledFragments: []
    )
    let type = DataDict(
        data: [
            "__typename": "pokemon_v2_type",
            "name": "electric"
        ],
        fulfilledFragments: []
    )
    let pokemonType = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemontype",
            "pokemon_v2_type": type
        ],
        fulfilledFragments: []
    )
    let color = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemoncolor",
            "name": "yellow"
        ],
        fulfilledFragments: []
    )
    let species = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemonspecies",
            "capture_rate": 190,
            "pokemon_v2_pokemoncolor": color
        ],
        fulfilledFragments: []
    )
    let defaultPokemon = DataDict(
        data: [
            "__typename": "pokemon_v2_pokemon",
            "id": 25,
            "name": "pikachu",
            "height": 4,
            "weight": 60,
            "pokemon_v2_pokemonabilities": [pokemonAbility],
            "pokemon_v2_pokemontypes": [pokemonType],
            "pokemon_v2_pokemonspecy": species
        ],
        fulfilledFragments: []
    )
    let selectedPokemon: DataDict? = includePokemon ? defaultPokemon : nil
    return PokemonAPI.PokemonDetailQuery.Data(
        _dataDict: DataDict(
            data: ["pokemon_v2_pokemon_by_pk": selectedPokemon],
            fulfilledFragments: []
        )
    )
}
