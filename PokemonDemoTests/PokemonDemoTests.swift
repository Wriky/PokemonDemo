import XCTest
@testable import PokemonDemo

final class PokemonDemoTests: XCTestCase {
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
        repository.complete(
            keyword: "new",
            offset: 0,
            with: [makeSpecies(id: 2, name: "new")]
        )
        repository.complete(
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
        repository.complete(
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
        repository.complete(
            keyword: "new",
            offset: 0,
            with: makeSpeciesPage(prefix: "new", startID: 101, count: 20)
        )
        await newSearch.value

        repository.complete(
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
        repository.complete(keyword: "new", offset: 20, with: [])
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
        repository.complete(
            keyword: "pika",
            offset: 0,
            with: makeSpeciesPage(prefix: "pika", startID: 1, count: 20)
        )
        await initialSearch.value

        let pagination = Task {
            await viewModel.loadMore()
        }
        await repository.waitForRequest(keyword: "pika", offset: 20)
        repository.complete(keyword: "pika", offset: 20, with: [])
        await pagination.value

        XCTAssertEqual(repository.requestedOffsets, [0, 20])
    }

    func testPokemonDetailBuildsOfficialArtworkURLFromID() {
        let detail = PokemonDetail(
            id: 25,
            name: "pikachu",
            abilityNames: [],
            typeNames: [],
            height: 4,
            weight: 60,
            captureRate: 190,
            colorName: "yellow"
        )

        XCTAssertEqual(
            detail.artworkURL?.absoluteString,
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"
        )
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
                .failure(PokemonRepositoryError.graphQL("boom")),
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
            PokemonRepositoryError.graphQL("boom").errorDescription,
            "boom"
        )
        XCTAssertEqual(
            PokemonRepositoryError.noData.errorDescription,
            "The server returned no usable Pokemon data."
        )
    }
}

@MainActor
private final class ControlledPokemonRepository: PokemonRepositoryProtocol {
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

@MainActor
private final class PokemonRepositoryFake: PokemonRepositoryProtocol {
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
