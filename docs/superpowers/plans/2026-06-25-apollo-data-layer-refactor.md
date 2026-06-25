# Apollo Data Layer Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the complete Pokémon data layer around Apollo iOS, isolate generated types, add deterministic tests, and close the remaining review findings without changing product behavior.

**Architecture:** ViewModels depend on `PokemonRepositoryProtocol`. `PokemonRepository` maps application DTOs into domain models and translates errors. `ApolloPokemonRemoteDataSource` maps generated Apollo results into DTOs, while `ApolloPokemonGraphQLExecutor` alone owns `ApolloClient`, generated query construction, cache-and-network stream handling, and Apollo error translation.

**Tech Stack:** Swift 5, Swift 6 concurrency checks, Apollo iOS 2.2, SwiftUI, XCTest, URLSession, URLCache.

---

### Task 1: Add DTO and mapper boundaries

**Files:**
- Create: `PokemonDemo/Classes/Network/DTOs/PokemonDTOs.swift`
- Create: `PokemonDemo/Classes/Network/Mappers/PokemonMapper.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add failing tests for species/detail mapping, stable trimming/deduplication, and invalid names.
- [ ] Run the focused mapper tests on the connected iPhone and confirm they fail because DTOs and `PokemonMapper` do not exist.
- [ ] Add immutable `Sendable` DTOs and a stateless mapper that validates positive IDs and non-empty names.
- [ ] Run the focused mapper tests and confirm they pass.

### Task 2: Add Repository orchestration and error translation

**Files:**
- Create: `PokemonDemo/Classes/Network/DataSources/PokemonRemoteDataSourceProtocol.swift`
- Replace: `PokemonDemo/Classes/Network/Repositories/ApolloPokemonRepository.swift`
- Modify: `PokemonDemo/Classes/Network/Repositories/PokemonRepositoryProtocol.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add failing tests proving search/detail argument forwarding, DTO mapping, and translation of no-data, GraphQL, transport, and mapping failures.
- [ ] Run the focused Repository tests and confirm they fail against the current concrete Apollo Repository.
- [ ] Introduce `PokemonRemoteDataSourceProtocol`, `PokemonRemoteDataSourceError`, and `PokemonRepository`.
- [ ] Keep `PokemonRepositoryProtocol` as the only ViewModel dependency and expose a production Repository factory.
- [ ] Run Repository and existing ViewModel tests and confirm they pass.

### Task 3: Isolate Apollo query execution

**Files:**
- Replace: `PokemonDemo/Classes/Network/Apollo/ApolloClientProvider.swift`
- Create: `PokemonDemo/Classes/Network/Apollo/PokemonGraphQLExecuting.swift`
- Create: `PokemonDemo/Classes/Network/Apollo/ApolloPokemonGraphQLExecutor.swift`
- Create: `PokemonDemo/Classes/Network/DataSources/ApolloPokemonRemoteDataSource.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add failing tests using generated selection-set initializers for search/detail DTO mapping, wildcard query forwarding, pagination variables, missing detail data, and GraphQL/transport error translation.
- [ ] Run the focused DataSource tests and confirm they fail because the new boundary does not exist.
- [ ] Add safe `URLComponents` endpoint construction and a production client factory with no force unwrap.
- [ ] Add the narrow executor protocol and Apollo-backed actor implementation using `.cacheAndNetwork`, final-response authority, and concise error translation.
- [ ] Add `ApolloPokemonRemoteDataSource` and keep generated types inside this subsystem.
- [ ] Run DataSource, Repository, and ViewModel tests and confirm they pass.

### Task 4: Unify artwork resources

**Files:**
- Modify: `PokemonDemo/Classes/Network/Models/PokemonModels.swift`
- Create: `PokemonDemo/Classes/Detail/Views/PokemonArtworkURLBuilder.swift`
- Modify: `PokemonDemo/Classes/Detail/Views/PokemonArtworkLoader.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Replace the obsolete domain-model artwork URL test with failing tests for ordered artwork URLs and Pokémon ID propagation.
- [ ] Run the focused artwork tests and confirm failure because the builder does not exist.
- [ ] Add `PokemonArtworkURLBuilder`, update the loader to use it, and remove `PokemonDetail.artworkURL`.
- [ ] Run artwork and Detail tests and confirm they pass.

### Task 5: Switch production injection and clean the project

**Files:**
- Modify: `PokemonDemo/Classes/Search/ViewModels/SearchViewModel.swift`
- Modify: `PokemonDemo/Classes/Detail/ViewModels/PokemonDetailViewModel.swift`
- Modify: `PokemonDemo/PokemonDemoApp.swift`
- Delete: `PokemonDemo/ContentView.swift`
- Modify: `.gitignore`
- Remove from Git index: `PokemonDemo.xcodeproj/xcuserdata/ryan.xcuserdatad/xcschemes/xcschememanagement.plist`

- [ ] Change ViewModel defaults from `ApolloPokemonRepository()` to `PokemonRepository.production`.
- [ ] Render `HomeView` directly from `PokemonDemoApp`.
- [ ] Delete the redundant forwarding view.
- [ ] Ignore Xcode user data and remove the tracked file from the index without deleting unrelated user files.
- [ ] Confirm no application source contains endpoint force unwraps and no `xcuserdata` remains tracked.

### Task 6: Update documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-06-25-p0-p1-remediation-design.md`
- Modify: `docs/superpowers/plans/2026-06-25-p0-p1-remediation.md`

- [ ] Document the final Repository/DataSource/Executor architecture.
- [ ] Document Apollo normalized cache as the only GraphQL cache.
- [ ] Replace obsolete `AsyncImage` statements with the cached URLSession artwork loader.
- [ ] Document DataSource, Repository, mapper, artwork, and ViewModel test coverage.

### Task 7: Full physical-device verification

**Files:**
- Verify all changed files.

- [ ] Run `git diff --check`.
- [ ] Run the complete test suite on `YY的iPhone`.
- [ ] Build the app for the same physical-device destination.
- [ ] Install and launch `com.yue.PokemonDemo`.
- [ ] Confirm App Icon compilation, iOS 17 effective deployment target, no tracked `xcuserdata`, and no endpoint force unwrap.
- [ ] Review the final diff against every requirement in the refactor design.
