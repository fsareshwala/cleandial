# Clean Dial — Feature Ledger & Provenance

This document tracks every implemented feature in **Clean Dial**
(`com.fsareshwala.contactformatter`), its default configuration, and the user intent and
implementation history behind it. AI agents must keep this file synchronized with code changes.

---

## Implemented Features (v1.1.3 Baseline)

### 1. Contacts Permission Flow & Authorization States

- **Behavior:** `MainView` inspects `CNContactStore.authorizationStatus(for: .contacts)` and routes
  to one of four experiences:
  - `.authorized` / `.limited` → `ContactListView`.
  - `.notDetermined` → `LandingView` displaying the Clean Dial logo (`LogoHeaderView`), three
    value-proposition callouts (formatting, switching formats, on-device privacy), and a prominent
    **Continue** button that requests Contacts access asynchronously and refreshes
    `authorizationStatus`.
  - `.denied` (and `@unknown default`) → `DeniedView` (`ActionView`) explaining access was denied
    with an **Open Settings** button pointing to `UIApplication.openSettingsURLString`.
  - `.restricted` → `RestrictedView` (`MessageView`) explaining access cannot be changed due to
    device restrictions such as parental controls.
- **Provenance & Rationale:** Originally launched directly into the contact list; refactored into
  dedicated authorization screens (`eda4637`, `361858b`, `e8fa462`, `3963bcd`, `e421525`) so users
  understand *why* Clean Dial requests Contacts access and that their contacts never leave the
  device before seeing the system permission prompt. The CTA wording was updated from "Grant
  Access" to "Continue" (`e654810`) to align with standard iOS onboarding conventions.
- **Key Files:** `contactformatter/MainView.swift`, `contactformatter/LandingView.swift`,
  `contactformatter/ActionView.swift`, `contactformatter/MessageView.swift`,
  `contactformatter/LogoHeaderView.swift`, `contactformatter/IconHeaderView.swift`,
  `contactformatter/ContactStoreService.swift`.

### 2. Standard Phone Number Format Selection

- **Behavior:** Displays a `Format Type` section at the top of `ContactListView` listing three
  selectable standard formats in order:
  1. `International` (**Default**, e.g., `+1 415-555-0100`)
  2. `National` (e.g., `(415) 555-0100`)
  3. `e.164` (e.g., `+14155550100`)
  Tapping an option updates `ContactListViewModel.selectedFormatType`, immediately recalculates
  which contacts need formatting and their preview strings, and logs `.formatTypeSelected`.
- **Provenance & Rationale:** Covers the three universal phone number formats supported by
  `PhoneNumberKit` (`PhoneNumberFormat`). Format examples were intentionally removed from the
  option rows (`84d520d`) to keep the format picker compact and uncluttered while the live contact
  list underneath previews the actual formatted output.
- **Key Files:** `contactformatter/FormatTypeView.swift`, `contactformatter/Contact.swift`,
  `contactformatter/SelectionIndicatorView.swift`, `contactformatter/ContactListViewModel.swift`.

### 3. Streaming Contact Enumeration, Partitioning & Auto-Refresh

- **Behavior:** `ContactStoreService.fetchContacts()` enumerates all device contacts on a detached
  `.userInitiated` task and yields one `Contact` per phone number via `AsyncStream<Contact>`,
  parsing each number once with `PhoneNumberUtility.parse(_:ignoreType: true)` using the shared
  `Contact.sharedPhoneNumberUtility`. `ContactListViewModel` ingests contacts in batches of 50,
  partitions them into `validContacts` and `invalidContacts`, and sorts both lists alphabetically
  by `CNContactFormatter` full name (falling back to `"Unknown name"`). Contacts reload
  automatically on launch, when the app returns to `.active` (`scenePhase`), via pull-to-refresh
  (`.refreshable`), and immediately after saving. Concurrent fetches are prevented via
  `isFetchingContacts`.
- **Provenance & Rationale:**
  - **Streaming in batches of 50 (`941b470`):** Monolithic background fetches stalled or were
    terminated on devices with large address books, falsely showing the empty "all formatted"
    state. Streaming incrementally resolved this.
  - **Key descriptors (`b5b20b7`, `7ac8b4d`):** Replaced manual individual name keys with
    `CNContactFormatter.descriptorForRequiredKeys(for: .fullName)` and
    `CNContactViewController.descriptorForRequiredKeys()` to eliminate `CNPropertyNotFetchedException`
    crashes.
  - **Re-entrancy guard (`bec5e41`):** Prevented duplicate rows when `init`, `scenePhase == .active`,
    and `.refreshable` triggered `getContacts()` concurrently.
  - **Auto-reload on foreground (`c9f690b`) & pull-to-refresh (`5f8ee5c`):** Keeps the list fresh
    when users edit contacts in the Contacts app or in `ContactDetailView`.
- **Key Files:** `contactformatter/ContactStoreService.swift`,
  `contactformatter/ContactListViewModel.swift`, `contactformatter/Contact.swift`,
  `contactformatter/ContactListView.swift`.

### 4. Contact Preview, Selective Checkboxes & Batch Formatting Save

- **Behavior:** The `Contacts` section lists only valid contacts whose current phone number differs
  from the target format (`formattedPhoneNumberIfNeeded(for:)`). Each row (`ContactView`) shows:
  - A selectable checkbox (`SelectionIndicatorView`, **default: checked**).
  - Contact full name and proposed formatted number on the top line.
  - Localized phone number label (e.g., `mobile`, `home`) and strikethrough original phone number
    on the bottom line.
  When no valid contacts need formatting, the section displays a `ContentUnavailableView`
  ("No Contacts" — "All contact phone numbers are formatted correctly") and hides the bottom-bar
  format action button (`person.crop.circle.badge.checkmark`). Tapping the format button disables
  interaction, displays a translucent `"Formatting..."` `ProgressView` overlay, writes each checked
  contact needing formatting back to `CNContactStore` (preserving its `CNLabeledValue` label and
  leaving other phone numbers on the same contact untouched), logs `.formatTypeSaved`, and reloads
  contacts.
- **Provenance & Rationale:**
  - Showing both the original strikethrough number and localized label (`5e8839c`) gives users full
    confidence before modifying their address book.
  - Representing each phone number as an independently checkable `Contact` lets users opt out of
    specific numbers without blocking batch formatting.
  - Hiding the bottom toolbar button and skipping saves when nothing needs formatting (`244d1e7`,
    `af81d60`, `ba52651`) prevents accidental no-op writes; the overlay (`20f9d71`, `f5c893c`)
    provides clear feedback during large saves.
- **Key Files:** `contactformatter/ContactListView.swift`, `contactformatter/ContactView.swift`,
  `contactformatter/SelectionIndicatorView.swift`, `contactformatter/Contact.swift`,
  `contactformatter/ContactListViewModel.swift`, `contactformatter/ContactStoreService.swift`.

### 5. Invalid Contacts Section, Info Sheet & In-App Editing

- **Behavior:** Contacts whose phone numbers cannot be parsed by `PhoneNumberKit` are grouped into
  an `Invalid Contacts` section (hidden when empty) displaying each contact's name, raw phone
  number, and localized label (`InvalidContactRowView`).
  - Tapping the section header's `info.circle` button opens `InvalidContactsInfoView` as a
    `.medium`-detent sheet with a yellow `WarningHeaderView` explaining why invalid contacts cannot
    be formatted.
  - Tapping an invalid contact row presents `ContactDetailView` (a `UIViewControllerRepresentable`
    wrapping `CNContactViewController` with `allowsEditing = true`) so the user can fix the phone
    number without leaving the app.
- **Provenance & Rationale:** Unparseable entries (short codes, extensions, typos, non-numeric
  strings) must never be corrupted by automated formatting (`0b7833a`, `6c77607`). Adding the
  `.medium` info sheet (`bee180c`, `281f844`), phone number label display (`7b83f6d`), and tap-to-edit
  `CNContactViewController` (`7ac8b4d`) turned dead-end warnings into an actionable in-app repair
  workflow.
- **Key Files:** `contactformatter/ContactListView.swift`, `contactformatter/ContactView.swift`,
  `contactformatter/InvalidContactsInfoView.swift`, `contactformatter/WarningHeaderView.swift`,
  `contactformatter/ContactDetailView.swift`, `contactformatter/Sheet.swift`.

### 6. About Sheet, Privacy Policy & Other Apps

- **Behavior:** Tapping the top-trailing `info.circle` toolbar button in `ContactListView` presents
  `AboutView` via `Sheet.about`, showing:
  - Rounded app icon (`AppIconInApp`), app title (`Clean Dial`), and version string from
    `Util.appVersion()`.
  - Links section: **Privacy Policy** (`NavigationLink` to `PrivacyPolicyView`), **Share Clean
    Dial** (`ShareLink` to the App Store listing), **Report a Bug** (GitHub Issues link), and
    **Source Code** (GitHub repository link), all sourced safely from `AppLinks`.
  - **Other Apps from the Developer** section (`OtherAppsView`) featuring `Forecash`
    (`AppInfo.forecash`), opening its App Store listing via `@Environment(\.openURL)`.
- **Provenance & Rationale:** Consolidates app version display (`cfb2379`), open-source
  transparency and privacy documentation (`cfa83b4`, `d1240b4`), bug reporting, App Store sharing,
  and cross-app discovery (`785b331`) in a clean modal sheet managed through the unified `Sheet`
  enum (`aee3496`).
- **Key Files:** `contactformatter/AboutView.swift`, `contactformatter/PrivacyPolicyView.swift`,
  `contactformatter/OtherAppsView.swift`, `contactformatter/Util.swift`,
  `contactformatter/Sheet.swift`.

### 7. Anonymous Usage Analytics & Crash Reporting

- **Behavior:** Configures Firebase (`FirebaseCore`, `FirebaseAnalytics`, `FirebaseCrashlytics`) on
  app launch in `AppDelegate`, disabling analytics collection in `DEBUG` builds. All 11 analytics
  events (`format_contacts`, `select_item` for saved format type, `format_type_selected`,
  `view_invalid_contacts_info`, `view_invalid_contact_detail`, `refresh_contacts`, `view_about`,
  `request_authorization`, `open_settings`, `tap_other_app`, `view_privacy_policy`) are defined in
  `AnalyticsEvent` and emitted through `FirebaseAnalyticsLogger`.
- **Provenance & Rationale:** Helps understand which phone number formats and features are used
  and catches crashes (`ea7988d`, `e533734`, `3d8ed86`, `7a80109`, `21ed5c9`) without ever
  collecting contact data. Disabling analytics in `DEBUG` (`f81a0c7`) keeps development sessions
  out of production metrics, and centralizing events behind `AnalyticsEvent` / `AnalyticsLogging`
  (`aaa7816`) prevents schema drift and enables unit test verification.
- **Key Files:** `contactformatter/contactformatterApp.swift`,
  `contactformatter/AnalyticsService.swift`, `GoogleService-Info.plist`.

### 8. Automated Xcode Cloud Build Versioning

- **Behavior:** `ci_scripts/ci_post_clone.sh` replaces `CURRENT_PROJECT_VERSION` in
  `contactformatter.xcodeproj/project.pbxproj` with Xcode Cloud's `$CI_BUILD_NUMBER` whenever
  present.
- **Provenance & Rationale:** Eliminates manual build-number bumps for TestFlight and App Store
  uploads (`a648654`).
- **Key Files:** `ci_scripts/ci_post_clone.sh`.
