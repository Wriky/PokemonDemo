# PokemonDemo Stability Fixes and App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix welcome initialization, debounce and stale searches, GraphQL error decoding, deployment-target inconsistency, and ship an original App Icon.

**Architecture:** Keep the existing SwiftUI/MVVM structure. Add small dependency seams around persistence and networking so behavior can be tested, centralize delayed search triggering in `SearchView`, and make GraphQL response validation explicit in `PokemonService`.

**Tech Stack:** SwiftUI, Combine, async/await, URLSession, XCTest, Xcode asset catalogs, AI-generated PNG assets.

---

### Task 1: Add the unit-test target

**Files:**
- Modify: `PokemonDemo.xcodeproj/project.pbxproj`
- Create: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Add a `PokemonDemoTests` unit-test target, product reference, sources/frameworks/resources phases, target dependency, Debug/Release configurations, and a shared scheme entry through the existing project structure.
- [ ] Add a smoke test importing `@testable import PokemonDemo`.
- [ ] Run `xcodebuild test` for the test target and confirm the baseline test passes.

### Task 2: Initialize welcome state synchronously

**Files:**
- Modify: `PokemonDemo/Classes/Home/ViewModels/HomeViewModel.swift`
- Modify: `PokemonDemo/Classes/Home/Views/HomeView.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Write a failing test showing a view model reads a supplied isolated `UserDefaults` suite.
- [ ] Run the focused test and confirm it fails because storage injection is unavailable.
- [ ] Inject `UserDefaults` into `HomeViewModel`, expose the current welcome value, and initialize `HomeView` state in `init`.
- [ ] Remove the delayed `onAppear` assignment.
- [ ] Re-run the test and confirm it passes.

### Task 3: Debounce explicit searches and reject stale results

**Files:**
- Modify: `PokemonDemo/Classes/Network/Services/PokemonService.swift`
- Modify: `PokemonDemo/Classes/Search/ViewModels/SearchViewModel.swift`
- Modify: `PokemonDemo/Classes/Search/Views/SearchView.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Write failing tests proving a newer search result wins over an older delayed response and repeated pending triggers can be cancelled.
- [ ] Run the focused tests and confirm the expected failures.
- [ ] Introduce a minimal `PokemonServicing` protocol implemented by `PokemonService`.
- [ ] Capture the searched keyword and a monotonically increasing request identifier in `SearchViewModel`; ignore completion from an outdated identifier.
- [ ] Store a cancellable search `Task` in `SearchView`, delay approximately 500 ms, cancel the previous pending task, and route button taps and keyboard submission through that trigger.
- [ ] Disable submission while a request is active and cancel the pending task when the view disappears.
- [ ] Re-run the focused tests and confirm they pass.

### Task 4: Decode GraphQL errors when data is null

**Files:**
- Modify: `PokemonDemo/Classes/Network/Services/PokemonService.swift`
- Modify: `PokemonDemoTests/PokemonDemoTests.swift`

- [ ] Write a failing URLProtocol-backed test for HTTP 200 with `{"data":null,"errors":[{"message":"boom"}]}`.
- [ ] Run the focused test and confirm decoding currently fails with a generic decoding error.
- [ ] Make response `data` optional, inspect `errors` first, and throw a dedicated invalid-data error when neither data nor errors are usable.
- [ ] Re-run the focused service tests and confirm they pass.

### Task 5: Normalize deployment targets

**Files:**
- Modify: `PokemonDemo.xcodeproj/project.pbxproj`

- [ ] Replace both project-level `IPHONEOS_DEPLOYMENT_TARGET = 26.4` settings with `17`.
- [ ] Run `xcodebuild -showBuildSettings` and confirm the effective deployment target is 17.

### Task 6: Generate and integrate App Icon assets

**Files:**
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- Create: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- Modify: `PokemonDemo/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] Generate a 1024×1024 original cute monster-collecting icon with no text or protected characters.
- [ ] Inspect the generated source for silhouette, edge safety, and small-size legibility.
- [ ] Produce dark and tinted-compatible variants without transparency.
- [ ] Update `Contents.json` filenames for standard, dark, and tinted appearances.
- [ ] Validate all images are 1024×1024 PNGs with opaque corners.

### Task 7: Final verification

**Files:**
- Verify all modified files.

- [ ] Run the complete unit-test suite.
- [ ] Build `PokemonDemo` for `generic/platform=iOS` with code signing disabled.
- [ ] Confirm the build log contains no App Icon asset errors.
- [ ] Run `git diff --check`.
- [ ] Review the final diff against every requirement in the design specification.
