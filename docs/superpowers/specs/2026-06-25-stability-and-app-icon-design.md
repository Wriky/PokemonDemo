# PokemonDemo Stability Fixes and App Icon Design

## Goal

Fix the four confirmed stability/configuration issues, add debounce protection to button and keyboard searches, and provide a production-ready App Icon without changing the quiz-required user flow.

## Scope

### Welcome state

- Inject a `UserDefaults` store into `HomeViewModel`.
- Initialize `HomeView`'s `hasSeenWelcome` state synchronously from the view model.
- Remove the delayed `onAppear` state update so returning users never render the welcome page first.

### Search debounce and stale request protection

- Route button taps and keyboard submission through one search trigger.
- Use a cancellable `Task` with an approximately 500 ms delay.
- A new trigger cancels the prior pending search.
- Disable the search button while a request is active.
- Add request identity protection in `SearchViewModel` so an older response cannot replace a newer search result.
- Preserve the current explicit-button search behavior; do not convert the screen to search-as-you-type.

### GraphQL errors

- Decode GraphQL `data` as optional.
- Inspect GraphQL `errors` before requiring data.
- Return a dedicated invalid-data error when a successful HTTP response contains neither usable data nor a GraphQL error.

### Deployment target

- Change the project-level Debug and Release deployment targets from `26.4` to `17`.
- Keep the existing target-level iOS 17 setting.

### Tests

- Add a unit-test target.
- Cover persisted welcome state initialization.
- Cover stale search response protection and repeated search behavior.
- Cover `data: null` plus GraphQL errors.
- Verify the deployment target through effective Xcode build settings.

### App Icon

- Generate an original 1024×1024 icon in a cute monster-collecting aesthetic.
- Visual concept: a friendly rounded creature, a red-and-white capture-ball motif, and a subtle magnifying-glass/search cue.
- Use bright blue, yellow, coral-red, and cream tones with strong silhouette and no text.
- Do not reproduce an existing Pokémon character, official Poké Ball artwork, franchise logo, or trademark.
- Produce standard, dark, and tinted-compatible icon assets and update `AppIcon.appiconset/Contents.json`.
- Validate square dimensions, opaque output, asset-catalog compilation, and appearance at small sizes.

## Validation

- Run focused unit tests and confirm the expected red-green cycle for behavior changes.
- Build the app for `generic/platform=iOS` with code signing disabled.
- Confirm effective `IPHONEOS_DEPLOYMENT_TARGET = 17`.
- Confirm the compiled app contains App Icon assets.

## Non-goals

- Apollo integration, Repository architecture, independent detail-page networking, live search, UI redesign, or unrelated refactoring.
