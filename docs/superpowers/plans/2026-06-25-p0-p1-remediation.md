# PokemonDemo P0/P1 Remediation Implementation Plan

> **Status note (2026-06-25):** The original Apollo Repository and `AsyncImage` portions of this historical plan were superseded by `2026-06-25-apollo-data-layer-refactor.md`. The final implementation uses `PokemonRepository` → `ApolloPokemonRemoteDataSource` → `ApolloPokemonGraphQLExecutor`, app-owned DTO/domain mapping, Apollo normalized in-memory caching, and a cached `URLSession` artwork loader with ordered fallbacks.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the handwritten GraphQL client with Apollo iOS v2, add repository-based dependency injection, and ship an independently loaded Hero-style Pokémon detail page while preserving all existing quiz behavior.

**Architecture:** Apollo-generated query types remain inside the data layer. The superseding implementation separates Repository, RemoteDataSource, and GraphQL Executor responsibilities before mapping application DTOs into `PokemonSpecies`, `Pokemon`, and `PokemonDetail` domain models consumed by MainActor ViewModels. Search retains explicit debouncing and pagination; detail performs its own repository request and renders a state-driven SwiftUI Hero layout.

**Tech Stack:** Swift 5, SwiftUI, async/await, Apollo iOS v2, Swift Package Manager, Apollo Codegen CLI, XCTest, URLSession, URLCache.

---

### Task 1: Preserve and commit the completed stability baseline

**Files:**
- Modify: `PokemonDemo.xcodeproj/project.pbxproj`
- Modify: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- Modify: `PokemonDemo/Classes/Home/ViewModels/HomeViewModel.swift`
- Modify: `PokemonDemo/Classes/Home/Views/HomeView.swift`
- Modify: `PokemonDemo/Classes/Network/Services/PokemonService.swift`
- Modify: `PokemonDemo/Classes/Search/ViewModels/SearchViewModel.swift`
- Create: `PokemonDemo/Classes/Search/ViewModels/SearchDebouncer.swift`
- Modify: `PokemonDemo/Classes/Search/Views/SearchView.swift`
- Create: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Run `git diff --check`.
- [ ] Build the generic iOS device target:

```bash
xcodebuild \
  -project PokemonDemo.xcodeproj \
  -scheme PokemonDemo \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/PokemonDemoBaseline \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] Confirm all deployment settings are 17:

```bash
rg 'IPHONEOS_DEPLOYMENT_TARGET = ' PokemonDemo.xcodeproj/project.pbxproj
```

Expected: every result ends in `17;`.

- [ ] Commit only project implementation and test changes; leave the quiz DOCX and review PDF untracked:

```bash
git add PokemonDemo PokemonDemoTests PokemonDemo.xcodeproj/project.pbxproj
git commit -m "fix: stabilize search and app startup"
```

### Task 2: Add Apollo iOS v2 package dependencies

**Files:**
- Modify: `PokemonDemo.xcodeproj/project.pbxproj`
- Create: `PokemonDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

- [ ] Add the remote package reference:

```text
https://github.com/apollographql/apollo-ios.git
```

Use the `upToNextMajorVersion` requirement beginning at `2.0.0`.

- [ ] Link the `Apollo` product to `PokemonDemo`.
- [ ] Link the `ApolloTestSupport` product to `PokemonDemoTests`.
- [ ] Resolve packages:

```bash
xcodebuild \
  -resolvePackageDependencies \
  -project PokemonDemo.xcodeproj \
  -scheme PokemonDemo \
  -clonedSourcePackagesDirPath .build/SourcePackages
```

Expected: Apollo packages resolve and `Package.resolved` is created or updated.

- [ ] Build the app and test target to verify package linkage before adding generated code.
- [ ] Commit:

```bash
git add PokemonDemo.xcodeproj
git commit -m "build: add Apollo iOS dependencies"
```

### Task 3: Add schema, operations, and Apollo code-generation configuration

**Files:**
- Create: `GraphQL/apollo-codegen-config.json`
- Create: `GraphQL/schema.graphqls`
- Create: `GraphQL/Operations/SearchPokemonSpecies.graphql`
- Create: `GraphQL/Operations/PokemonDetail.graphql`
- Create: `PokemonDemo/Classes/Network/Generated/`

- [ ] Add `GraphQL/Operations/SearchPokemonSpecies.graphql`:

```graphql
query SearchPokemonSpecies($pattern: String!, $limit: Int!, $offset: Int!) {
  pokemon_v2_pokemonspecies(
    where: { name: { _ilike: $pattern } }
    limit: $limit
    offset: $offset
    order_by: { id: asc }
  ) {
    id
    name
    capture_rate
    pokemon_v2_pokemoncolor {
      id
      name
    }
    pokemon_v2_pokemons(order_by: { id: asc }) {
      id
      name
      pokemon_v2_pokemonabilities(order_by: { id: asc }) {
        id
        pokemon_v2_ability {
          name
        }
      }
    }
  }
}
```

- [ ] Add `GraphQL/Operations/PokemonDetail.graphql`:

```graphql
query PokemonDetail($id: Int!) {
  pokemon_v2_pokemon_by_pk(id: $id) {
    id
    name
    height
    weight
    pokemon_v2_pokemonabilities(order_by: { id: asc }) {
      id
      pokemon_v2_ability {
        name
      }
    }
    pokemon_v2_pokemontypes(order_by: { slot: asc }) {
      pokemon_v2_type {
        name
      }
    }
    pokemon_v2_pokemonspecy {
      capture_rate
      pokemon_v2_pokemoncolor {
        name
      }
    }
  }
}
```

- [ ] Add `GraphQL/apollo-codegen-config.json` with:

```json
{
  "schemaNamespace": "PokemonAPI",
  "schemaDownloadConfiguration": {
    "downloadMethod": {
      "introspection": {
        "endpointURL": "https://beta.pokeapi.co/graphql/v1beta",
        "httpMethod": "POST",
        "includeDeprecatedInputValues": false,
        "outputFormat": "SDL"
      }
    },
    "downloadTimeout": 60,
    "headers": [],
    "outputPath": "GraphQL/schema.graphqls"
  },
  "input": {
    "operationSearchPaths": ["GraphQL/Operations/**/*.graphql"],
    "schemaSearchPaths": ["GraphQL/schema.graphqls"]
  },
  "output": {
    "testMocks": {
      "none": {}
    },
    "schemaTypes": {
      "path": "PokemonDemo/Classes/Network/Generated",
      "moduleType": {
        "embeddedInTarget": {
          "name": "PokemonDemo"
        }
      }
    },
    "operations": {
      "inSchemaModule": {}
    }
  }
}
```

- [ ] Install the Apollo Codegen CLI using the resolved package:

```bash
swift package \
  --disable-sandbox \
  --package-path .build/SourcePackages/checkouts/apollo-ios \
  apollo-cli-install
```

Expected: an executable named `apollo-ios-cli` is installed at the repository root.

- [ ] Download schema introspection:

```bash
./apollo-ios-cli fetch-schema --path GraphQL/apollo-codegen-config.json
```

Expected: `GraphQL/schema.graphqls` contains the PokeAPI schema in SDL format.

- [ ] Run code generation from repository root:

```bash
./apollo-ios-cli generate --path GraphQL/apollo-codegen-config.json
```

Expected: generated schema and operation Swift files under `PokemonDemo/Classes/Network/Generated`.

- [ ] Build the generic iOS target to prove generated sources compile.
- [ ] Commit:

```bash
git add GraphQL PokemonDemo/Classes/Network/Generated
git commit -m "build: generate typed PokeAPI operations"
```

### Task 4: Define app-owned models and repository protocol

**Files:**
- Modify: `PokemonDemo/Classes/Network/Models/PokemonModels.swift`
- Create: `PokemonDemo/Classes/Network/Repositories/PokemonRepositoryProtocol.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Write a failing sprite URL test:

```swift
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
```

- [ ] Run the focused test and verify it fails because `PokemonDetail` is missing.
- [ ] Add:

```swift
struct PokemonDetail: Equatable, Sendable {
    let id: Int
    let name: String
    let abilityNames: [String]
    let typeNames: [String]
    let height: Int?
    let weight: Int?
    let captureRate: Int?
    let colorName: String?

    var artworkURL: URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png")
    }
}
```

- [ ] Add:

```swift
protocol PokemonRepositoryProtocol: Sendable {
    func searchSpecies(keyword: String, limit: Int, offset: Int) async throws -> [PokemonSpecies]
    func pokemonDetail(id: Int) async throws -> PokemonDetail
}
```

- [ ] Mark domain models `Sendable` where their stored values allow it.
- [ ] Re-run focused tests and commit:

```bash
git add PokemonDemo/Classes/Network/Models PokemonDemo/Classes/Network/Repositories PokemonDemoTests
git commit -m "feat: define Pokemon repository contract"
```

### Task 5: Implement the Apollo data-layer boundaries

**Files:**
- Create: `PokemonDemo/Classes/Network/Apollo/ApolloClientProvider.swift`
- Create: `PokemonDemo/Classes/Network/Apollo/ApolloPokemonGraphQLExecutor.swift`
- Create: `PokemonDemo/Classes/Network/DataSources/ApolloPokemonRemoteDataSource.swift`
- Create: `PokemonDemo/Classes/Network/Repositories/PokemonRepository.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add mapping tests using generated selection-set initializers or `ApolloTestSupport` mocks for:
  - Search species name, capture rate, color, Pokémon, and ability mapping.
  - Detail name, abilities, types, height, weight, capture rate, and color mapping.
  - Apollo GraphQL errors translated into the repository error message.
- [ ] Verify the mapping tests fail because the new boundaries do not exist.
- [ ] Construct the endpoint without force unwrap and create the Apollo client through `ApolloClientProvider`.

```swift
enum PokemonRepositoryError: LocalizedError, Equatable {
    case noData
    case unavailable
    case invalidData
    case server(String)
}
```

- [ ] Implement the executor, DataSource, and Repository with narrow injected protocols:
  - Apollo fetch policy: `.cacheAndNetwork`.
  - The final cache-and-network response is authoritative.
  - GraphQL errors are checked before data mapping.
  - `%keyword%`, limit, and offset are passed through generated variables.
- [ ] Map generated operation data into DTOs in the DataSource, then DTOs into domain models in `PokemonRepository`.
- [ ] Run repository tests, then commit:

```bash
git add PokemonDemo/Classes/Network/Apollo PokemonDemo/Classes/Network/Repositories PokemonDemoTests
git commit -m "feat: implement Apollo Pokemon repository"
```

### Task 6: Migrate search to repository injection

**Files:**
- Modify: `PokemonDemo/Classes/Search/ViewModels/SearchViewModel.swift`
- Modify: `PokemonDemo/Classes/Search/Views/SearchView.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Replace the test fake's `PokemonServicing` conformance with `PokemonRepositoryProtocol`, adding an unreachable `pokemonDetail(id:)` implementation for search-only tests.
- [ ] Add a test proving pagination calls offsets `0`, then `20`, and appends results.
- [ ] Verify the test fails before migration.
- [ ] Replace `PokemonServicing` storage with:

```swift
private let repository: any PokemonRepositoryProtocol

init(repository: any PokemonRepositoryProtocol = PokemonRepository.production) {
    self.repository = repository
}
```

- [ ] Route `search()` and `loadMore()` through `repository.searchSpecies`.
- [ ] Preserve request IDs, debounce, loading states, and error behavior.
- [ ] Increase list background color opacity from `0.18` to `0.5`; keep white mapped to a semantic system background.
- [ ] Run search tests and commit:

```bash
git add PokemonDemo/Classes/Search PokemonDemoTests
git commit -m "refactor: migrate search to Apollo repository"
```

### Task 7: Make detail independently load repository data

**Files:**
- Modify: `PokemonDemo/Classes/Detail/ViewModels/PokemonDetailViewModel.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add a success test:

```swift
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
```

- [ ] Add an error-and-retry test where the first request fails and the second succeeds.
- [ ] Verify both fail with the old ViewModel.
- [ ] Replace the existing ViewModel with:

```swift
@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published private(set) var detail: PokemonDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let placeholderName: String
    private let pokemonID: Int
    private let repository: any PokemonRepositoryProtocol

    init(
        pokemonID: Int,
        placeholderName: String,
        repository: any PokemonRepositoryProtocol = PokemonRepository.production
    ) {
        self.pokemonID = pokemonID
        self.placeholderName = placeholderName
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await repository.pokemonDetail(id: pokemonID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] Run detail tests and commit:

```bash
git add PokemonDemo/Classes/Detail/ViewModels PokemonDemoTests
git commit -m "feat: load Pokemon detail independently"
```

### Task 8: Build the Hero detail UI

**Files:**
- Modify: `PokemonDemo/Classes/Detail/Views/PokemonDetailView.swift`
- Modify: `PokemonDemo/Classes/Search/Views/SearchView.swift`
- Create: `PokemonDemo/Classes/Detail/Views/PokemonArtworkView.swift`
- Create: `PokemonDemo/Classes/Detail/Views/PokemonTypeChip.swift`

- [ ] Change navigation construction to pass `pokemon.id` and `pokemon.name`.
- [ ] Update `PokemonDetailView` initialization to create the new ViewModel.
- [ ] Trigger initial loading with:

```swift
.task {
    await viewModel.load()
}
```

- [ ] Implement loading state with a centered `ProgressView` and descriptive accessibility label.
- [ ] Implement failure state with message and Retry button invoking `await viewModel.load()`.
- [ ] Implement Hero content:
  - `PokemonArtworkView` backed by the cached `PokemonArtworkLoader`.
  - Ordered official-artwork, standard, and home sprite fallbacks derived from Pokémon ID.
  - 240-point maximum artwork size.
  - Name and `#ID`.
  - Type chips using semantic colors.
  - Ability chips/cards.
  - Height, weight, and capture-rate cards.
  - Hero background mapped from `colorName` at approximately 0.35–0.5 opacity.
- [ ] Add a styled placeholder icon when artwork fails.
- [ ] Use adaptive stacks and `minimumScaleFactor` rather than fixed text sizes.
- [ ] Add VoiceOver labels for artwork and stat cards.
- [ ] Build the generic iOS target and commit:

```bash
git add PokemonDemo/Classes/Detail PokemonDemo/Classes/Search/Views/SearchView.swift
git commit -m "feat: add Hero Pokemon detail page"
```

### Task 9: Add explicit HomeViewModel actor isolation

**Files:**
- Modify: `PokemonDemo/Classes/Home/ViewModels/HomeViewModel.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add explicit `@MainActor` to `HomeViewModel`.
- [ ] Ensure welcome tests execute on MainActor and continue to pass.
- [ ] Commit:

```bash
git add PokemonDemo/Classes/Home/ViewModels/HomeViewModel.swift PokemonDemoTests
git commit -m "refactor: clarify HomeViewModel actor isolation"
```

### Task 10: Remove the handwritten GraphQL client

**Files:**
- Delete: `PokemonDemo/Classes/Network/Services/PokemonService.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Confirm no production references remain:

```bash
rg 'PokemonService|PokemonServicing|GraphQLRequest|GraphQLValue|GraphQLResponse' PokemonDemo PokemonDemoTests
```

Expected: only temporary test references, which must be migrated or removed before deletion.

- [ ] Delete the handwritten service and URLProtocol-specific test.
- [ ] Replace the old service error test with repository/Apollo error translation coverage.
- [ ] Build and test, then commit:

```bash
git add -A PokemonDemo/Classes/Network PokemonDemoTests
git commit -m "refactor: remove handwritten GraphQL client"
```

### Task 11: Add project documentation

**Files:**
- Create: `README.md`

- [ ] Document:
  - Original quiz behavior.
  - SwiftUI/MVVM/Repository/Apollo architecture.
  - iOS 17 deployment target.
  - Apollo package resolution.
  - Schema download and code-generation commands.
  - Search debounce and pagination.
  - Detail loading and artwork source.
  - Test command.
  - Physical-device acceptance checklist.
- [ ] Include this device checklist:

```markdown
## Physical Device Check

1. Launch twice and confirm the welcome page appears only on first launch.
2. Tap Search rapidly and confirm only the last request runs.
3. Open a Pokémon and confirm artwork, types, abilities, and stats load.
4. Disable networking, retry detail, and confirm an inline error appears.
5. Return to search and confirm results are preserved.
6. Confirm the App Icon appears correctly in standard and dark appearances.
```

- [ ] Commit:

```bash
git add README.md
git commit -m "docs: add setup and architecture guide"
```

### Task 12: Final verification and physical-device handoff

**Files:**
- Verify all changed files.

- [ ] Run all tests:

```bash
xcodebuild test \
  -project PokemonDemo.xcodeproj \
  -scheme PokemonDemo \
  -destination 'platform=iOS Simulator,id=4068AF67-B77F-4047-A0FB-52EF5F11CD17' \
  -derivedDataPath /tmp/PokemonDemoP0P1Tests \
  CODE_SIGNING_ALLOWED=NO
```

Expected: all tests pass with zero failures.

- [ ] Build the generic device target:

```bash
xcodebuild \
  -project PokemonDemo.xcodeproj \
  -scheme PokemonDemo \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/PokemonDemoP0P1Build \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] Confirm Apollo is linked and generated sources are present:

```bash
rg 'apollo-ios|Apollo' PokemonDemo.xcodeproj/project.pbxproj PokemonDemo/Classes/Network
find PokemonDemo/Classes/Network/Generated -type f -name '*.swift' | sort
```

- [ ] Confirm no handwritten GraphQL transport remains:

```bash
rg 'URLSession|GraphQLRequest|GraphQLValue' PokemonDemo/Classes/Network
```

Expected: no matches in the application network layer.

- [ ] Run `git diff --check`.
- [ ] Review the diff against every P0/P1 requirement.
- [ ] Notify the user to run the physical-device checklist; do not ask them to perform simulator validation.
