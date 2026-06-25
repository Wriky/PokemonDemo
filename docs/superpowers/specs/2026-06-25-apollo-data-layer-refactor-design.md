# Apollo Data Layer Refactor Design

## Goal

Refactor the complete data layer while retaining Apollo iOS as the GraphQL implementation. The resulting architecture must isolate Apollo-generated types from the domain and presentation layers, make every behavior testable without live networking, preserve the current application behavior, and close the remaining findings from the code review.

## Scope

This refactor covers:

- Apollo client configuration and endpoint safety.
- GraphQL query execution and cache policy.
- Remote data transfer models.
- Mapping into application-owned domain models.
- Repository orchestration and error translation.
- Dependency injection into Search and Detail ViewModels.
- Artwork URL construction and image loading consistency.
- Data-layer, ViewModel, and regression tests.
- Removal of tracked Xcode user data and the redundant root forwarding view.
- Documentation updates describing the final architecture and verification.

Generated Apollo schema and operation files remain generated artifacts. Their contents will not be manually edited.

## Architecture

The final dependency flow is:

```text
SwiftUI View
    ↓
MainActor ViewModel
    ↓
PokemonRepositoryProtocol
    ↓
PokemonRepository
    ↓
PokemonRemoteDataSourceProtocol
    ↓
ApolloPokemonRemoteDataSource
    ↓
PokemonGraphQLExecuting
    ↓
ApolloPokemonGraphQLExecutor
    ↓
ApolloClient + Normalized Cache
```

The layers have the following responsibilities:

### Presentation

Search and Detail Views render state and forward user actions. Search and Detail ViewModels depend only on `PokemonRepositoryProtocol`. Neither layer imports Apollo nor references generated GraphQL types.

### Domain

Application-owned domain models remain small, immutable, `Sendable` value types:

- `PokemonSpecies`
- `PokemonColor`
- `Pokemon`
- `PokemonDetail`

The domain layer contains no GraphQL field names, Apollo selection sets, transport concepts, or cache implementation.

### Repository

`PokemonRepository` implements `PokemonRepositoryProtocol`. It:

- Requests remote DTOs from `PokemonRemoteDataSourceProtocol`.
- Uses dedicated mappers to create domain models.
- Converts data-source and mapping failures into stable repository errors.
- Contains no Apollo query construction or response iteration.
- Does not maintain a second application-owned cache.

### Remote Data Source

`ApolloPokemonRemoteDataSource` is the boundary that converts generated operation data into application DTOs. It:

- Requests generated Search and Detail operation data through `PokemonGraphQLExecuting`.
- Distinguishes missing usable data from valid empty search results.
- Converts generated selection sets into data-layer DTOs.
- Never exposes Apollo-generated types through its protocol.

`ApolloPokemonGraphQLExecutor` is the only application-written type that owns a concrete `ApolloClient`. It:

- Builds generated Search and Detail queries.
- Applies the selected Apollo cache policy.
- Iterates cache-and-network response streams.
- Treats the final network response as authoritative.
- Rejects GraphQL responses containing errors.
- Translates Apollo transport failures into remote data-source errors.

## Data Transfer Models

The remote data source returns immutable DTOs defined by the application:

```swift
struct PokemonSpeciesDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let captureRate: Int?
    let color: PokemonColorDTO?
    let pokemons: [PokemonDTO]
}

struct PokemonColorDTO: Equatable, Sendable {
    let id: Int
    let name: String
}

struct PokemonDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
}

struct PokemonDetailDTO: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
    let typeNames: [String]
    let height: Int?
    let weight: Int?
    let captureRate: Int?
    let colorName: String?
}
```

DTOs deliberately resemble the current domain models because the API response is small. They remain separate so GraphQL mapping and domain mapping can evolve independently and be tested at their own boundaries.

## Apollo Client and Cache

The application will keep one shared production `ApolloClient`.

The GraphQL endpoint will be assembled without force-unwrapping:

```swift
enum PokemonAPIConfiguration {
    static var endpoint: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "beta.pokeapi.co"
        components.path = "/graphql/v1beta"
        return components.url
            ?? URL(fileURLWithPath: "/invalid-pokemon-api-endpoint")
    }
}
```

The local file URL is a deterministic, non-crashing fallback for an impossible configuration failure; it will surface through normal transport error handling. Production construction will be isolated behind a factory so tests never depend on the shared client.

Apollo's normalized cache is the only GraphQL data cache. The repository must not introduce a second memory or disk cache.

Search and Detail use Apollo's cache-and-network behavior:

- Cached data may be emitted immediately.
- The final network response is authoritative.
- A final GraphQL or transport failure is surfaced even when cached data was previously available.
- Empty search data maps to an empty list.
- Missing Detail data maps to `noData`.

## Error Model

The data layer uses two error boundaries.

### Remote Data Source Errors

```swift
enum PokemonRemoteDataSourceError: Error, Equatable, Sendable {
    case noData
    case graphQL(String)
    case transport(String)
}
```

Apollo-specific error objects do not escape the data source. GraphQL errors use the first concise server message. Transport errors use a deterministic, user-safe message instead of exposing implementation details.

### Repository Errors

```swift
enum PokemonRepositoryError: LocalizedError, Equatable, Sendable {
    case noData
    case unavailable
    case invalidData
    case server(String)
}
```

Repository translation is:

- Remote `noData` → repository `noData`.
- Remote `graphQL(message)` → repository `server(message)`.
- Remote `transport` → repository `unavailable`.
- DTO mapping failure → repository `invalidData`.

User-facing descriptions remain concise and stable so ViewModels can display `localizedDescription` without understanding the source of the failure.

## Mapping

Mapping is split into two explicit boundaries:

1. Apollo generated selection sets → DTOs inside `ApolloPokemonRemoteDataSource`.
2. DTOs → domain models inside `PokemonMapper`.

`PokemonMapper` is stateless and exposes pure functions. It validates required identifiers and non-empty names. Invalid required values produce a mapping error rather than silently creating unusable domain objects.

Ability and type names are compacted, trimmed, deduplicated while preserving response order, and empty values are discarded.

## Dependency Injection

Production defaults remain convenient:

```swift
SearchViewModel(
    repository: PokemonRepository.production
)
```

`PokemonRepository.production` owns an `ApolloPokemonRemoteDataSource` configured by the production Apollo client factory.

Tests inject:

- A fake repository for ViewModel behavior.
- A fake remote data source for Repository behavior.
- A mocked Apollo operation executor for DataSource behavior.

No dependency injection framework will be added.

## Apollo Test Boundary

The data source will depend on a narrow application-owned operation executor rather than concrete `ApolloClient`:

```swift
protocol PokemonGraphQLExecuting: Sendable {
    func searchSpecies(
        pattern: String,
        limit: Int,
        offset: Int
    ) async throws -> PokemonAPI.SearchPokemonSpeciesQuery.Data

    func pokemonDetail(
        id: Int
    ) async throws -> PokemonAPI.PokemonDetailQuery.Data
}
```

This protocol is private to the remote-data-source subsystem; generated types do not escape into Repository, domain, ViewModel, or View code. `ApolloPokemonGraphQLExecutor` wraps the concrete Apollo client and generated queries. This gives the Apollo integration one narrow test seam and prevents a fake from having to implement Apollo's broad client surface.

The executor owns stream iteration, final-response selection, GraphQL error inspection, and Apollo transport translation. The data source owns required-data validation and DTO construction. The repository owns domain mapping and public error translation.

The concrete executor is an `actor` so the non-`Sendable` Apollo client remains isolated behind one concurrency boundary. Protocol fakes may also be actors. Repository and data-source value types remain `Sendable`.

## Artwork Resource Layer

Artwork loading remains separate from GraphQL data.

`PokemonArtworkURLBuilder` becomes the single source of artwork URLs. It returns an ordered list:

1. Official artwork through jsDelivr.
2. Standard sprite through jsDelivr.
3. Home artwork through jsDelivr.

`PokemonDetail.artworkURL` will be removed to avoid maintaining a second URL definition that the UI does not use.

`PokemonArtworkLoader` continues to provide:

- `URLSession`-backed loading.
- `URLCache`.
- Ordered fallback.
- Bounded retry.
- Cancellation checks.

Tests validate the URL builder and fallback ordering without making live network requests. The design documentation will explicitly record that the implementation intentionally uses a custom cached loader instead of `AsyncImage`.

## Presentation Preservation

The refactor must preserve:

- Explicit button and keyboard search.
- Approximately 500 ms debounce.
- Stale search and stale pagination protection.
- Pagination offsets and no-more-data behavior.
- Species grouping and the clarified section header.
- Search state retained when returning from Detail.
- Independently loaded Detail data.
- Detail loading, failure, retry, and empty states.
- Hero artwork, name, ID, type chips, abilities, stats, and color tint.
- Dynamic Type and existing accessibility labels.

No visual redesign is included.

## Project Cleanup

The following review findings will be closed as part of the same change:

- Remove the redundant `ContentView`; `PokemonDemoApp` renders `HomeView` directly.
- Add `*.xcuserdata/` or the equivalent Xcode user-data patterns to `.gitignore`.
- Remove the currently tracked `PokemonDemo.xcodeproj/xcuserdata` file from the Git index.
- Preserve local user data on disk where possible; only repository tracking is removed.
- Update README architecture, image loading, testing, code generation, and physical-device verification sections.
- Update the existing P0/P1 remediation design and plan where they still describe `AsyncImage` or the pre-refactor repository.

## Testing Strategy

All behavior changes follow test-first development.

### Mapper Tests

- Search DTO maps species, color, Pokémon, and abilities.
- Detail DTO maps abilities, types, stats, capture rate, and color.
- Empty or whitespace-only required names fail mapping.
- Ability and type values are trimmed and deduplicated in stable order.

### Repository Tests

- Search passes keyword, limit, and offset to the data source.
- Detail passes Pokémon ID to the data source.
- DTOs map into expected domain models.
- `noData`, GraphQL, transport, and mapping errors translate correctly.

### GraphQL Executor and DataSource Tests

- Search wraps the keyword as `%keyword%`.
- Search forwards pagination variables.
- Detail forwards the selected ID.
- Cache-and-network uses the final response.
- GraphQL errors are rejected.
- Transport failures are translated.
- Empty search data returns an empty array.
- Missing Detail data returns `noData`.

DataSource tests use generated selection-set initializers or Apollo test support. Executor tests use a stubbed Apollo network transport and normalized cache. They never contact PokeAPI.

### Artwork Tests

- URL order is deterministic.
- Every URL contains the requested Pokémon ID.
- The primary URL is the official artwork path.
- Fallback loading stops after the first valid image.
- Invalid responses proceed to the next URL.

### Existing Regression Tests

Existing welcome, debounce, stale search, stale pagination, pagination offset, Detail loading, and retry tests remain.

## Verification

Final verification runs against the connected iPhone 15 Pro:

1. `git diff --check`.
2. Confirm no tracked `xcuserdata`.
3. Confirm no application-written force unwrap for endpoint construction.
4. Run the complete unit-test suite on the physical device.
5. Build the application for the physical-device destination.
6. Install and launch the application.
7. Manually verify search, pagination, Detail navigation, artwork fallback, retry, back navigation, light appearance, and dark appearance.

The automated test result bundle path and executed test count will be recorded in the final handoff.

## Non-Goals

- Replacing Apollo with REST or another GraphQL client.
- Adding an application-owned cache above Apollo.
- Adding offline persistence.
- Adding UseCase classes between ViewModels and Repository.
- Adding Swinject or another dependency injection framework.
- Rewriting generated Apollo sources.
- Redesigning the existing UI.
- Adding UI-test automation in this refactor.

## Deliverables

- Apollo operation executor abstraction and implementation.
- Remote data source protocol and Apollo implementation.
- Data-layer DTOs.
- Dedicated domain mapper.
- Refactored Repository implementation.
- Unified data-layer error translation.
- Unified artwork URL builder and updated loader.
- Updated ViewModel production injection.
- Comprehensive data-layer and regression tests.
- Xcode user-data cleanup.
- Removal of redundant `ContentView`.
- Updated design, implementation plan, and README.
