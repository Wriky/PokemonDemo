import XCTest
@testable import PokemonDemo

final class PokemonDemoTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
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
        let service = ControlledPokemonService()
        let viewModel = SearchViewModel(service: service)

        viewModel.keyword = "old"
        let oldSearch = Task {
            await viewModel.search()
        }

        await service.waitForRequest(keyword: "old", offset: 0)

        viewModel.keyword = "new"
        let newSearch = Task {
            await viewModel.search()
        }

        await service.waitForRequest(keyword: "new", offset: 0)
        service.complete(
            keyword: "new",
            offset: 0,
            with: [makeSpecies(id: 2, name: "new")]
        )
        service.complete(
            keyword: "old",
            offset: 0,
            with: [makeSpecies(id: 1, name: "old")]
        )

        await oldSearch.value
        await newSearch.value

        XCTAssertEqual(viewModel.speciesList.map(\.name), ["new"])
    }

    func testOldPaginationResponseCannotMutateNewSearchState() async {
        let service = ControlledPokemonService()
        let viewModel = SearchViewModel(service: service)

        viewModel.keyword = "old"
        let initialSearch = Task {
            await viewModel.search()
        }
        await service.waitForRequest(keyword: "old", offset: 0)
        service.complete(
            keyword: "old",
            offset: 0,
            with: makeSpeciesPage(prefix: "old", startID: 1, count: 20)
        )
        await initialSearch.value

        let oldPagination = Task {
            await viewModel.loadMore()
        }
        await service.waitForRequest(keyword: "old", offset: 20)

        viewModel.keyword = "new"
        let newSearch = Task {
            await viewModel.search()
        }
        await service.waitForRequest(keyword: "new", offset: 0)
        service.complete(
            keyword: "new",
            offset: 0,
            with: makeSpeciesPage(prefix: "new", startID: 101, count: 20)
        )
        await newSearch.value

        service.complete(
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
        await service.waitForRequest(keyword: "new", offset: 20)
        service.complete(keyword: "new", offset: 20, with: [])
        await newPagination.value
    }

    func testGraphQLErrorIsReportedWhenDataIsNull() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = Data(#"{"data":null,"errors":[{"message":"boom"}]}"#.utf8)
            return (response, data)
        }

        let service = PokemonService(session: URLSession(configuration: configuration))

        do {
            _ = try await service.searchSpecies(keyword: "pik", limit: 20, offset: 0)
            XCTFail("Expected a GraphQL server error")
        } catch let error as PokemonServiceError {
            guard case let .serverError(message) = error else {
                return XCTFail("Expected serverError, got \(error)")
            }
            XCTAssertEqual(message, "boom")
        } catch {
            XCTFail("Expected PokemonServiceError, got \(error)")
        }
    }
}

@MainActor
private final class ControlledPokemonService: PokemonServicing {
    private struct RequestKey: Hashable {
        let keyword: String
        let offset: Int
    }

    private var requests: Set<RequestKey> = []
    private var requestWaiters: [RequestKey: [CheckedContinuation<Void, Never>]] = [:]
    private var responseContinuations: [RequestKey: CheckedContinuation<[PokemonSpecies], Never>] = [:]

    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        let key = RequestKey(keyword: keyword, offset: offset)
        requests.insert(key)
        requestWaiters.removeValue(forKey: key)?.forEach { $0.resume() }

        return await withCheckedContinuation { continuation in
            responseContinuations[key] = continuation
        }
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

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    nonisolated override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    nonisolated override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    nonisolated override func stopLoading() {}
}
