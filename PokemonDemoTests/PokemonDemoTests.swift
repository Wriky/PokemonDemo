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

    func testSearchDebouncerOnlyRunsLatestScheduledAction() async throws {
        let debouncer = SearchDebouncer(delay: .milliseconds(50))
        var executedValues: [Int] = []

        debouncer.schedule {
            executedValues.append(1)
        }
        debouncer.schedule {
            executedValues.append(2)
        }

        try await Task.sleep(for: .milliseconds(120))

        XCTAssertEqual(executedValues, [2])
    }

    func testNewerSearchResultWinsWhenOlderRequestFinishesLast() async throws {
        let service = DelayedPokemonService()
        let viewModel = SearchViewModel(service: service)

        viewModel.keyword = "old"
        let oldSearch = Task {
            await viewModel.search()
        }

        try await Task.sleep(for: .milliseconds(10))

        viewModel.keyword = "new"
        let newSearch = Task {
            await viewModel.search()
        }

        await oldSearch.value
        await newSearch.value

        XCTAssertEqual(viewModel.speciesList.map(\.name), ["new"])
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

private struct DelayedPokemonService: PokemonServicing {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies] {
        if keyword == "old" {
            try await Task.sleep(for: .milliseconds(120))
        } else {
            try await Task.sleep(for: .milliseconds(20))
        }

        return [
            PokemonSpecies(
                id: keyword == "old" ? 1 : 2,
                name: keyword,
                captureRate: 45,
                color: nil,
                pokemons: []
            )
        ]
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
