# PokemonDemo P0/P1 Remediation Design

## Goal

Address every P0 and P1 recommendation in the review report while preserving the original quiz behavior and the stability fixes already implemented.

## Confirmed Baseline

The following report items are already implemented and must remain covered:

- Explicit-search debounce and stale response protection.
- Unit-test target and regression tests.
- Welcome state initialized synchronously.
- Project and target deployment settings use iOS 17.
- App Icon assets are present.

## Apollo iOS Migration

- Add Apollo iOS v2 through Swift Package Manager.
- Use Apollo's Codegen CLI and checked-in configuration.
- Download and check in the PokeAPI GraphQL schema used for generation.
- Add two checked-in GraphQL operations:
  - Paginated fuzzy species search.
  - Pokémon detail query by Pokémon ID.
- Generate Swift operation and schema types into a dedicated `PokemonAPI` module namespace.
- Create one application-owned `ApolloClient` configured for the existing PokeAPI GraphQL endpoint and normalized in-memory caching.
- Remove the handwritten GraphQL request, value encoding, response decoding, and service-error implementation after generated queries are integrated.
- Map Apollo-generated response objects into app-owned domain models so SwiftUI and ViewModels do not depend directly on generated types.

## Repository and Dependency Injection

- Introduce a `PokemonRepositoryProtocol` with search and detail methods.
- Implement `PokemonRepository` as the domain-facing mapper and error-translation boundary.
- Keep generated GraphQL types inside `ApolloPokemonGraphQLExecutor` and `ApolloPokemonRemoteDataSource`.
- Convert generated results into application-owned DTOs before mapping them into domain models.
- Make the executor the only component that owns and invokes `ApolloClient`.
- Inject the repository into both Search and Detail ViewModels.
- Keep default initializers for production convenience while allowing protocol-based fakes in tests.
- Update tests to use Repository, DataSource, and executor fakes at their respective boundaries.
- Do not add Swinject; manual initializer injection is sufficient and keeps the demo lightweight.

## Search

- Preserve the existing button and keyboard search flow.
- Preserve approximately 500 ms cancellable debounce.
- Preserve pagination, fuzzy search, loading, empty, error, and stale-response behavior.
- Continue grouping Pokémon under species because this matches the quiz requirement.
- Increase species background color strength from `0.18` to approximately `0.5`, with readable text in light and dark appearances.
- Keep search results alive while navigating to and from detail.

## Detail Data

- `PokemonDetailViewModel` must independently fetch detail data using the selected Pokémon ID.
- Detail state includes initial loading, loaded content, empty fallback, failure, and retry.
- The detail query should fetch:
  - Pokémon ID and name.
  - Ability names.
  - Height and weight.
  - Pokémon types.
  - Species capture rate and color when available.
- The detail page must not rely on the search result for final displayed data. The passed Pokémon object may provide an immediate title placeholder only.

## Detail UI: Hero Card

- Use the confirmed Hero layout:
  - Large image region at the top.
  - Pokémon name and ID.
  - Type chips.
  - Ability cards/chips.
  - Compact basic-stat row for height, weight, and capture rate.
- Load Pokémon artwork using a dedicated async `URLSession` loader.
- Use ordered official PokeAPI sprite URLs derived from Pokémon ID, stopping after the first valid image.
- Use memory/disk `URLCache` and bounded retries for artwork requests.
- Show a styled placeholder when an image is unavailable.
- Tint the Hero background using the species color at a readable opacity.
- Support Dynamic Type, light/dark appearance, and VoiceOver labels.
- Use the existing navigation back behavior so search results remain retained.

## Actor Isolation

- Add explicit `@MainActor` to `HomeViewModel` for consistency and clarity even though project default isolation is MainActor.
- Keep Search and Detail ViewModels explicitly `@MainActor`.
- Ensure repository callbacks bridge safely into async/await without mutating UI state off the main actor.

## Error Handling

- Translate Apollo transport and GraphQL errors into concise user-facing repository errors.
- Search failures continue to preserve the existing error presentation.
- Detail failures display an inline retry action.
- Cache reads may provide immediate data, but network refresh failures must still be represented accurately.

## Testing

- Preserve the existing welcome and debounce tests.
- Update stale-search tests to use a repository fake.
- Add tests for:
  - DTO-to-domain mapping and invalid required values.
  - Repository forwarding and error translation.
  - Search/detail DataSource mapping and pagination variables.
  - Apollo cache-and-network final response handling.
  - Detail loading success.
  - Detail error and retry.
  - Sprite URL construction and fallback stopping behavior.
  - Apollo GraphQL error translation.
- Run all tests and build the generic iOS device target.
- Final user acceptance is performed on a physical iPhone, per user preference.

## Deliverables

- Apollo SPM dependency and code-generation configuration.
- Checked-in schema, GraphQL operation files, and generated Swift sources.
- Repository protocol and Apollo implementation.
- Updated Search and Detail ViewModels and Views.
- Updated tests.
- Updated README with setup, architecture, code generation, and physical-device verification steps.

## Non-goals

- Swinject or another DI framework.
- A third-party image-loading library.
- Mutations, subscriptions, authentication, or offline persistence.
- A full app-wide visual redesign.
