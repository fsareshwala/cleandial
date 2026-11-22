# Clean Dial — Agent & Architecture Guide

## 1. Product Vision & User Intent

**Clean Dial** (`cleandial`) is a focused, privacy-first, open-source iOS utility (inspired
by Android's Twitch 2) that lets users batch-format phone numbers in their iOS Contacts address book
into a consistent standard format—**International**, **National**, or **e.164**—entirely on-device.
Users preview every before/after change, can uncheck individual numbers they want to skip, and can
tap unparseable ("invalid") contacts to fix them directly in the native iOS Contacts editor.

## 2. Project Identifiers, Targets & Dependencies

- **App Display Name:** Clean Dial
- **Xcode Project & Scheme:** `cleandial` (`cleandial.xcodeproj`)
- **App Target & Bundle ID:** `cleandial` (`com.fsareshwala.contactformatter`)
  - **Minimum Deployment Target:** iOS 17.6 (iPhone & iPad)
  - **File Organization:** Uses Xcode's `PBXFileSystemSynchronizedRootGroup`; files placed in
    `cleandial/` are automatically included in the app target.
- **Unit Test Target & Bundle ID:** `cleandialTests`
  (`com.fsareshwala.contactformatterTests`) — uses the **Swift Testing** framework
  (`import Testing`).
- **UI Test Target & Bundle ID:** `cleandialUITests`
  (`com.fsareshwala.contactformatterUITests`) — uses **XCTest / XCUIAutomation**.
- **Swift Package Dependencies:**
  - `PhoneNumberKit` (`PhoneNumberUtility`, `PhoneNumberFormat`, `PhoneNumber`) for local phone
    number parsing and formatting.
  - `Firebase` (`FirebaseCore`, `FirebaseAnalytics`, `FirebaseCrashlytics`) for anonymous usage
    analytics and crash reporting.
- **CI/CD:** `ci_scripts/ci_post_clone.sh` runs in Xcode Cloud to set `CURRENT_PROJECT_VERSION` from
  `$CI_BUILD_NUMBER`.

## 3. Core Architectural Invariants

- **Strict Privacy & On-Device Processing:** All contact reading, parsing, formatting, and writing
  happens exclusively on-device via `Contacts.framework`. Never upload, persist externally, or
  attach personal contact data (names, phone numbers, labels) to analytics events or crash logs.
  Firebase Analytics collection is explicitly disabled under `#if DEBUG` in
  `cleandialApp.swift`.
- **Contacts Framework Required Key Descriptors:** `ContactStoreService.fetchContacts()` MUST always
  include:
  - `CNContactTypeKey`
  - `CNContactPhoneNumbersKey`
  - `CNContactFormatter.descriptorForRequiredKeys(for: .fullName)`
  - `CNContactViewController.descriptorForRequiredKeys()`
  Manually enumerating individual name keys previously caused runtime
  `CNPropertyNotFetchedException` crashes when formatting certain contact types or presenting
  `ContactDetailView`.
- **Streaming Contact Enumeration & Re-entrancy Guard:** `ContactStoreService.fetchContacts()`
  streams contacts via `AsyncStream<Contact>` on a detached `.userInitiated` task, and
  `ContactListViewModel` ingests them in batches of 50 while guarded by `isFetchingContacts`.
  Never replace this with a single monolithic fetch or remove the re-entrancy guard—large address
  books previously timed out / failed to populate, and overlapping `init`, `scenePhase`, and
  pull-to-refresh triggers previously produced duplicate rows.
- **Shared `PhoneNumberUtility` & Value-Type `Contact`:** `Contact` is a `struct` representing a
  single `(CNContact, CNLabeledValue<CNPhoneNumber>)` pair so contacts with multiple numbers can be
  independently checked and formatted. Always reuse `Contact.sharedPhoneNumberUtility` (whose
  internal `RegexManager` is thread-safe); never allocate a new `PhoneNumberUtility()` per contact.
- **Testable Service Boundaries:**
  - Keep `CNContactStore` access behind `ContactStoreProviding` (`ContactStoreService`) and pure
    mutation helpers (`ContactStoreService.makeUpdatedContact(from:replacing:with:)`).
  - Keep all Firebase Analytics events strongly typed in `AnalyticsEvent` and logged through
    `AnalyticsLogging` (`FirebaseAnalyticsLogger.shared`). Do not scatter raw `Analytics.logEvent`
    string literals across views.
- **Modern SwiftUI & Concurrency Conventions:**
  - Use `@Observable` (Observation framework) rather than Combine's `ObservableObject`/`@Published`.
  - Prefer Swift `async`/`await` APIs (e.g., `CNContactStore.requestAccess(for:)`) over completion
    handlers to avoid background-thread SwiftUI state mutations.
  - Use `@State private var` for local view state, `@Environment(\.openURL)` /
    `@Environment(\.dismiss)` instead of `UIApplication.shared.open`, modern SwiftUI modifiers
    (`.foregroundStyle`, `.clipShape`), and safe URL handling via `AppLinks` (no force unwrapping).
  - Reuse shared UI primitives (`IconHeaderView`, `SelectionIndicatorView`, `MessageView`,
    `ActionView`, `Sheet`) rather than duplicating layout code.
- **Testing & Verification:**
  - Add/update Swift Testing unit tests in `cleandialTests/cleandialTests.swift` using
    mock `ContactStoreProviding` and `AnalyticsLogging` implementations.
  - Use explicit international country codes in test phone numbers (e.g., `+14155550100`,
    `+442079460958`) so formatting assertions are locale-independent.
  - Run tests on an iOS Simulator destination (test targets do not configure device signing teams).

## 4. Feature Provenance & Living Documentation Rule (MANDATORY)

Detailed feature behavior, user rationale, and implementation history live in `docs/FEATURES.md`.

- **Before implementing a new feature or changing existing behavior:** Read `docs/FEATURES.md` to
  understand existing constraints and why current defaults exist.
- **After implementing or modifying any user-facing feature:** You MUST update `docs/FEATURES.md` in
  the same task/commit. Add or update the feature entry with:
  1. **What changed** (UI, contact formatting/storage behavior, analytics events).
  2. **Provenance & Rationale** (why the user requested it and any edge-case decisions made).
  3. **Files touched**.
