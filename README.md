# PokemonDemo

SwiftUI demo app for searching Pokémon species via the PokeAPI GraphQL endpoint and viewing independently loaded detail pages.

## Quiz Behavior

- First launch shows a welcome screen; returning users go directly to search.
- Search uses an explicit button and keyboard submit (not search-as-you-type).
- Species results are grouped in sections; tap a Pokémon name to open detail.
- Search supports pagination with a load-more footer.

## Architecture

- **UI:** SwiftUI with `NavigationStack`
- **Pattern:** MVVM with manual repository injection
- **Networking:** Apollo iOS v2 with checked-in schema and generated operations
- **Data:** `ApolloPokemonRepository` maps generated GraphQL types into app-owned models
- **Concurrency:** Swift 6 strict concurrency with `@MainActor` ViewModels

## Requirements

- Xcode 26+
- iOS 17 deployment target
- Swift 5

## Setup

1. Open `PokemonDemo.xcodeproj` in Xcode.
2. Resolve Swift Package Manager dependencies (Apollo iOS 2.x).
3. Build and run on a simulator or device.

## GraphQL Code Generation

Configuration lives in `GraphQL/apollo-codegen-config.json`.

Download or refresh the schema:

```bash
./apollo-ios-cli fetch-schema --path GraphQL/apollo-codegen-config.json
```

Generate Swift types:

```bash
./apollo-ios-cli generate --path GraphQL/apollo-codegen-config.json
```

Fetch schema and generate in one step:

```bash
./apollo-ios-cli generate --path GraphQL/apollo-codegen-config.json --fetch-schema
```

Generated sources are written to `PokemonDemo/Classes/Network/Generated`.

## Search Behavior

- Approximately 500 ms debounce on button and keyboard search triggers.
- Stale responses are ignored via monotonically increasing request IDs.
- Species list background colors use `pokemon_v2_pokemoncolor.name` at ~50% opacity.

## Detail Page

- Detail loads independently by Pokémon ID through `PokemonRepositoryProtocol`.
- Artwork uses the official PokeAPI sprites CDN URL derived from Pokémon ID.
- Hero layout shows artwork, name, ID, type chips, abilities, and basic stats.

## Tests

```bash
xcodebuild test \
  -project PokemonDemo.xcodeproj \
  -scheme PokemonDemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

Coverage includes welcome persistence, debounce, stale search protection, pagination offsets, detail loading/retry, and artwork URL construction.

## Physical Device Check

1. Launch twice and confirm the welcome page appears only on first launch.
2. Tap Search rapidly and confirm only the last request runs.
3. Open a Pokémon and confirm artwork, types, abilities, and stats load.
4. Disable networking, retry detail, and confirm an inline error appears.
5. Return to search and confirm results are preserved.
6. Confirm the App Icon appears correctly in standard and dark appearances.
