import Contacts
import FirebaseAnalytics
import Foundation
import OtherApps
import PhoneNumberKit
import Testing

@testable import cleandial

// MARK: - Test Helpers

private func makeCNContact(
  givenName: String = "",
  familyName: String = "",
  phoneNumbers: [(label: String?, value: String)] = []
) -> CNContact {
  let contact = CNMutableContact()
  contact.givenName = givenName
  contact.familyName = familyName
  contact.phoneNumbers = phoneNumbers.map {
    CNLabeledValue(label: $0.label, value: CNPhoneNumber(stringValue: $0.value))
  }
  return contact.copy() as! CNContact
}

private func makeContact(
  givenName: String = "Alice",
  familyName: String = "",
  phoneNumber: String,
  label: String? = CNLabelPhoneNumberMobile,
  isChecked: Bool = true
) -> Contact {
  let cnContact = makeCNContact(
    givenName: givenName,
    familyName: familyName,
    phoneNumbers: [(label: label, value: phoneNumber)]
  )
  return Contact(
    deviceContact: cnContact,
    devicePhoneNumber: cnContact.phoneNumbers[0],
    isChecked: isChecked
  )
}

private final class MockContactStore: ContactStoreProviding, @unchecked Sendable {
  private let lock = NSLock()

  var status: CNAuthorizationStatus = .authorized
  var requestAccessResult: Result<Bool, Error> = .success(true)
  var contactsToStream: [Contact] = []
  var streamDelayNanoseconds: UInt64 = 0

  private(set) var requestAccessCallCount = 0
  private(set) var fetchCallCount = 0
  private(set) var savedBatches: [(contacts: [Contact], format: PhoneNumberFormat)] = []

  func authorizationStatus() -> CNAuthorizationStatus {
    lock.withLock { status }
  }

  func requestAccess() async throws -> Bool {
    let result = lock.withLock {
      requestAccessCallCount += 1
      return requestAccessResult
    }
    return try result.get()
  }

  func fetchContacts() -> AsyncStream<Contact> {
    let (contacts, delay) = lock.withLock {
      fetchCallCount += 1
      return (contactsToStream, streamDelayNanoseconds)
    }

    return AsyncStream { continuation in
      Task {
        if delay > 0 {
          try? await Task.sleep(nanoseconds: delay)
        }

        for contact in contacts {
          continuation.yield(contact)
        }

        continuation.finish()
      }
    }
  }

  func saveFormattedContacts(_ contacts: [Contact], toFormat format: PhoneNumberFormat) async {
    lock.withLock {
      savedBatches.append((contacts: contacts, format: format))
    }
  }
}

private final class MockAnalyticsLogger: AnalyticsLogging, @unchecked Sendable {
  private let lock = NSLock()
  private(set) var loggedEvents: [AnalyticsEvent] = []

  func log(_ event: AnalyticsEvent) {
    lock.withLock {
      loggedEvents.append(event)
    }
  }
}

private final class MockBundle: Bundle, @unchecked Sendable {
  private let mockInfoDictionary: [String: Any]?

  init(infoDictionary: [String: Any]?) {
    self.mockInfoDictionary = infoDictionary
    super.init()
  }

  override var infoDictionary: [String: Any]? {
    mockInfoDictionary
  }
}

// MARK: - Contact Tests

@Suite("Contact Tests")
struct ContactTests {
  @Test func validUSPhoneNumberFormatsCorrectly() {
    let contact = makeContact(phoneNumber: "+14155550100")

    #expect(contact.hasValidPhoneNumber)
    #expect(contact.phoneNumber == "+14155550100")
    #expect(contact.formatPhoneNumber(.e164) == "+14155550100")
    #expect(contact.formatPhoneNumber(.international) == "+1 415-555-0100")
    #expect(contact.formatPhoneNumber(.national) == "(415) 555-0100")
  }

  @Test func validInternationalPhoneNumberFormatsCorrectly() {
    let contact = makeContact(phoneNumber: "+442079460958")

    #expect(contact.hasValidPhoneNumber)
    #expect(contact.formatPhoneNumber(.e164) == "+442079460958")
    #expect(contact.formatPhoneNumber(.international) == "+44 20 7946 0958")
    #expect(contact.formatPhoneNumber(.national) == "020 7946 0958")
  }

  @Test(arguments: ["", "abc", "123", "not-a-number", "---"])
  func invalidPhoneNumbersAreMarkedInvalid(rawNumber: String) {
    let contact = makeContact(phoneNumber: rawNumber)

    #expect(!contact.hasValidPhoneNumber)
    for format in PhoneNumberFormat.allOptions {
      #expect(!contact.needsFormatting(toFormat: format))
      #expect(contact.formattedPhoneNumberIfNeeded(for: format) == nil)
    }
  }

  @Test func needsFormattingAndFormattedIfNeededWhenUnformatted() {
    let contact = makeContact(phoneNumber: "+14155550100")

    #expect(contact.needsFormatting(toFormat: .international))
    #expect(contact.formattedPhoneNumberIfNeeded(for: .international) == "+1 415-555-0100")

    #expect(contact.needsFormatting(toFormat: .national))
    #expect(contact.formattedPhoneNumberIfNeeded(for: .national) == "(415) 555-0100")

    #expect(!contact.needsFormatting(toFormat: .e164))
    #expect(contact.formattedPhoneNumberIfNeeded(for: .e164) == nil)
  }

  @Test(arguments: [
    (PhoneNumberFormat.international, "+1 415-555-0100"),
    (PhoneNumberFormat.national, "(415) 555-0100"),
    (PhoneNumberFormat.e164, "+14155550100"),
  ])
  func alreadyFormattedContactDoesNotNeedFormatting(
    format: PhoneNumberFormat,
    formattedNumber: String
  ) {
    let contact = makeContact(phoneNumber: formattedNumber)

    #expect(contact.hasValidPhoneNumber)
    #expect(!contact.needsFormatting(toFormat: format))
    #expect(contact.formattedPhoneNumberIfNeeded(for: format) == nil)
  }

  @Test func contactNameUsesFullNameAndFallsBackToUnknown() {
    let named = makeContact(givenName: "Alice", familyName: "", phoneNumber: "+14155550100")
    #expect(named.name == "Alice")

    let unnamed = makeContact(givenName: "", familyName: "", phoneNumber: "+14155550100")
    #expect(unnamed.name == "Unknown name")
  }

  @Test func phoneNumberLabelReturnsLocalizedValueOrEmpty() {
    let mobile = makeContact(phoneNumber: "+14155550100", label: CNLabelPhoneNumberMobile)
    let expectedLocalized = CNLabeledValue<CNPhoneNumber>.localizedString(
      forLabel: CNLabelPhoneNumberMobile
    )
    #expect(mobile.phoneNumberLabel == expectedLocalized)

    let unlabeled = makeContact(phoneNumber: "+14155550100", label: nil)
    #expect(unlabeled.phoneNumberLabel.isEmpty)
  }

  @Test func isCheckedDefaultsToTrueAndRespectsInitialValue() {
    let defaultChecked = makeContact(phoneNumber: "+14155550100")
    #expect(defaultChecked.isChecked)

    let unchecked = makeContact(phoneNumber: "+14155550100", isChecked: false)
    #expect(!unchecked.isChecked)
  }
}

// MARK: - PhoneNumberFormat Tests

@Suite("PhoneNumberFormat Tests")
struct PhoneNumberFormatTests {
  @Test func allOptionsPreservesDisplayOrder() {
    #expect(PhoneNumberFormat.allOptions == [.international, .national, .e164])
  }

  @Test(arguments: [
    (PhoneNumberFormat.international, "International", "International"),
    (PhoneNumberFormat.national, "National", "National"),
    (PhoneNumberFormat.e164, "e.164", "E164"),
  ])
  func displayAndAnalyticsNamesMatchExpectedValues(
    format: PhoneNumberFormat,
    expectedDisplayName: String,
    expectedAnalyticsName: String
  ) {
    #expect(format.displayName == expectedDisplayName)
    #expect(format.analyticsName == expectedAnalyticsName)
  }
}

// MARK: - ContactStoreService Tests

@Suite("ContactStoreService Tests")
struct ContactStoreServiceTests {
  @Test func makeUpdatedContactReplacesTargetPhoneNumberAndPreservesOthers() {
    let cnContact = makeCNContact(
      givenName: "Alice",
      phoneNumbers: [
        (label: CNLabelHome, value: "+14155550100"),
        (label: CNLabelWork, value: "+14155550199"),
      ]
    )

    let updated = ContactStoreService.makeUpdatedContact(
      from: cnContact,
      replacing: cnContact.phoneNumbers[1],
      with: "+1 415-555-0199"
    )

    #expect(updated != nil)
    #expect(updated?.phoneNumbers.count == 2)
    #expect(updated?.phoneNumbers[0].value.stringValue == "+14155550100")
    #expect(updated?.phoneNumbers[0].label == CNLabelHome)
    #expect(updated?.phoneNumbers[1].value.stringValue == "+1 415-555-0199")
    #expect(updated?.phoneNumbers[1].label == CNLabelWork)
  }

  @Test func makeUpdatedContactReturnsNilWhenPhoneNumberNotFound() {
    let cnContact = makeCNContact(
      givenName: "Alice",
      phoneNumbers: [(label: CNLabelHome, value: "+14155550100")]
    )
    let missingPhoneNumber = CNLabeledValue(
      label: CNLabelWork,
      value: CNPhoneNumber(stringValue: "+14155559999")
    )

    let updated = ContactStoreService.makeUpdatedContact(
      from: cnContact,
      replacing: missingPhoneNumber,
      with: "+1 415-555-9999"
    )

    #expect(updated == nil)
  }
}

// MARK: - ContactListViewModel Tests

@Suite("ContactListViewModel Tests")
@MainActor
struct ContactListViewModelTests {
  @Test func getContactsPartitionsAndSortsWhenAuthorized() async {
    let store = MockContactStore()
    store.status = .authorized
    store.contactsToStream = [
      makeContact(givenName: "Zoe", phoneNumber: "+14155550101"),
      makeContact(givenName: "Bob", phoneNumber: "invalid-1"),
      makeContact(givenName: "Alice", phoneNumber: "+14155550102"),
      makeContact(givenName: "Aaron", phoneNumber: "invalid-2"),
    ]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(viewModel.validContacts.map(\.name) == ["Alice", "Zoe"])
    #expect(viewModel.invalidContacts.map(\.name) == ["Aaron", "Bob"])
    #expect(store.requestAccessCallCount == 0)
    #expect(store.fetchCallCount == 1)
  }

  @Test func getContactsFetchesWhenLimited() async {
    let store = MockContactStore()
    store.status = .limited
    store.contactsToStream = [makeContact(givenName: "Alice", phoneNumber: "+14155550100")]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(viewModel.validContacts.count == 1)
    #expect(store.fetchCallCount == 1)
  }

  @Test func getContactsRequestsAccessWhenNotDeterminedAndFetchesIfGranted() async {
    let store = MockContactStore()
    store.status = .notDetermined
    store.requestAccessResult = .success(true)
    store.contactsToStream = [makeContact(givenName: "Alice", phoneNumber: "+14155550100")]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(store.requestAccessCallCount == 1)
    #expect(store.fetchCallCount == 1)
    #expect(viewModel.validContacts.count == 1)
  }

  @Test func getContactsSkipsFetchWhenNotDeterminedAndAccessDenied() async {
    let store = MockContactStore()
    store.status = .notDetermined
    store.requestAccessResult = .success(false)
    store.contactsToStream = [makeContact(givenName: "Alice", phoneNumber: "+14155550100")]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(store.requestAccessCallCount == 1)
    #expect(store.fetchCallCount == 0)
    #expect(viewModel.validContacts.isEmpty)
  }

  @Test func getContactsHandlesRequestAccessErrorGracefully() async {
    enum SampleError: Error { case failed }

    let store = MockContactStore()
    store.status = .notDetermined
    store.requestAccessResult = .failure(SampleError.failed)

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(store.requestAccessCallCount == 1)
    #expect(store.fetchCallCount == 0)
    #expect(viewModel.validContacts.isEmpty)
  }

  @Test(arguments: [CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted])
  func getContactsDoesNotFetchWhenUnauthorized(status: CNAuthorizationStatus) async {
    let store = MockContactStore()
    store.status = status
    store.contactsToStream = [makeContact(givenName: "Alice", phoneNumber: "+14155550100")]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    await viewModel.getContacts()

    #expect(store.requestAccessCallCount == 0)
    #expect(store.fetchCallCount == 0)
    #expect(viewModel.validContacts.isEmpty)
  }

  @Test(arguments: [0, 5, 12])
  func getContactsHandlesBatchBoundariesAndRemainder(totalContacts: Int) async {
    let store = MockContactStore()
    store.status = .authorized
    store.contactsToStream = (0..<totalContacts).map { index in
      let isValid = index.isMultiple(of: 2)
      let number: String
      if isValid {
        number = "+141555501\(String(format: "%02d", index))"
      } else {
        number = "bad-\(index)"
      }

      return makeContact(givenName: String(format: "User%02d", index), phoneNumber: number)
    }

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      batchSize: 5,
      loadOnInit: false
    )

    await viewModel.getContacts()

    let expectedValid = (0..<totalContacts).filter { $0.isMultiple(of: 2) }.count
    let expectedInvalid = totalContacts - expectedValid
    #expect(viewModel.validContacts.count == expectedValid)
    #expect(viewModel.invalidContacts.count == expectedInvalid)
    #expect(viewModel.validContacts.map(\.name) == viewModel.validContacts.map(\.name).sorted())
    #expect(
      viewModel.invalidContacts.map(\.name) == viewModel.invalidContacts.map(\.name).sorted()
    )
  }

  @Test func getContactsPreventsConcurrentFetches() async {
    let store = MockContactStore()
    store.status = .authorized
    store.streamDelayNanoseconds = 50_000_000
    store.contactsToStream = [makeContact(givenName: "Alice", phoneNumber: "+14155550100")]

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )

    async let firstFetch: Void = viewModel.getContacts()
    async let secondFetch: Void = viewModel.getContacts()
    _ = await (firstFetch, secondFetch)

    #expect(store.fetchCallCount == 1)
  }

  @Test func anyContactNeedsFormattingRespondsToSelectedFormatType() {
    let viewModel = ContactListViewModel(
      contactStore: MockContactStore(),
      analytics: MockAnalyticsLogger(),
      loadOnInit: false
    )
    viewModel.validContacts = [makeContact(phoneNumber: "+1 415-555-0100")]

    viewModel.selectedFormatType = .international
    #expect(!viewModel.anyContactNeedsFormatting())

    viewModel.selectedFormatType = .e164
    #expect(viewModel.anyContactNeedsFormatting())

    viewModel.selectedFormatType = .national
    #expect(viewModel.anyContactNeedsFormatting())
  }

  @Test func saveContactsSavesOnlyCheckedContactsNeedingFormattingLogsAndRefreshes() async {
    let store = MockContactStore()
    let analytics = MockAnalyticsLogger()

    let checkedNeedsFormatting = makeContact(
      givenName: "Alice",
      phoneNumber: "+14155550100",
      isChecked: true
    )
    let uncheckedNeedsFormatting = makeContact(
      givenName: "Bob",
      phoneNumber: "+14155550101",
      isChecked: false
    )
    let alreadyFormatted = makeContact(
      givenName: "Charlie",
      phoneNumber: "+1 415-555-0102",
      isChecked: true
    )

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: analytics,
      loadOnInit: false
    )
    viewModel.selectedFormatType = .international
    viewModel.validContacts = [
      checkedNeedsFormatting,
      uncheckedNeedsFormatting,
      alreadyFormatted,
    ]

    await viewModel.saveContacts()

    #expect(store.savedBatches.count == 1)
    #expect(store.savedBatches[0].format == .international)
    #expect(store.savedBatches[0].contacts.map(\.name) == ["Alice"])
    #expect(analytics.loggedEvents == [.formatTypeSaved(.international)])
    #expect(store.fetchCallCount == 1)
  }

  @Test func saveContactsSkipsWhenNoContactsNeedFormatting() async {
    let store = MockContactStore()
    let analytics = MockAnalyticsLogger()

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: analytics,
      loadOnInit: false
    )
    viewModel.selectedFormatType = .international
    viewModel.validContacts = [makeContact(phoneNumber: "+1 415-555-0100")]

    await viewModel.saveContacts()

    #expect(store.savedBatches.isEmpty)
    #expect(analytics.loggedEvents.isEmpty)
    #expect(store.fetchCallCount == 0)
  }

  @Test func saveContactsSkipsWhenNeedingFormattingContactsAreUnchecked() async {
    let store = MockContactStore()
    let analytics = MockAnalyticsLogger()

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: analytics,
      loadOnInit: false
    )
    viewModel.selectedFormatType = .international
    viewModel.validContacts = [
      makeContact(phoneNumber: "+14155550100", isChecked: false)
    ]

    await viewModel.saveContacts()

    #expect(store.savedBatches.isEmpty)
    #expect(analytics.loggedEvents.isEmpty)
    #expect(store.fetchCallCount == 0)
  }

  @Test(arguments: PhoneNumberFormat.allOptions)
  func saveContactsLogsExpectedFormatTypeEvent(format: PhoneNumberFormat) async {
    let store = MockContactStore()
    let analytics = MockAnalyticsLogger()

    let rawNumber: String
    if format == .e164 {
      rawNumber = "+1 415-555-0100"
    } else {
      rawNumber = "+14155550100"
    }

    let viewModel = ContactListViewModel(
      contactStore: store,
      analytics: analytics,
      loadOnInit: false
    )
    viewModel.selectedFormatType = format
    viewModel.validContacts = [makeContact(phoneNumber: rawNumber)]

    await viewModel.saveContacts()

    #expect(analytics.loggedEvents == [.formatTypeSaved(format)])
    #expect(store.savedBatches.first?.format == format)
  }
}

// MARK: - AnalyticsEvent Tests

@Suite("AnalyticsEvent Tests")
struct AnalyticsEventTests {
  @Test func formatContactsEventMatchesSchema() {
    for format in PhoneNumberFormat.allOptions {
      let event = AnalyticsEvent.formatContacts(format)
      #expect(event.name == "format_contacts")
      #expect(event.parameters?["format"] as? String == format.rawValue)
    }
  }

  @Test func formatTypeSavedEventMatchesSchema() {
    for format in PhoneNumberFormat.allOptions {
      let event = AnalyticsEvent.formatTypeSaved(format)
      #expect(event.name == AnalyticsEventSelectItem)
      #expect(event.parameters?[AnalyticsParameterItemID] as? String == "format-type")
      #expect(event.parameters?[AnalyticsParameterItemName] as? String == "Format Type")
      #expect(
        event.parameters?[AnalyticsParameterContentType] as? String == format.analyticsName
      )
    }
  }

  @Test func formatTypeSelectedEventMatchesSchema() {
    for format in PhoneNumberFormat.allOptions {
      let event = AnalyticsEvent.formatTypeSelected(format)
      #expect(event.name == "format_type_selected")
      #expect(event.parameters?["type"] as? String == format.displayName)
    }
  }

  @Test func tapOtherAppEventMatchesSchema() {
    let event = AnalyticsEvent.tapOtherApp(name: "Forecash")
    #expect(event.name == "tap_other_app")
    #expect(event.parameters?["app_name"] as? String == "Forecash")
  }

  @Test(arguments: [
    (AnalyticsEvent.viewInvalidContactsInfo, "view_invalid_contacts_info"),
    (AnalyticsEvent.viewInvalidContactDetail, "view_invalid_contact_detail"),
    (AnalyticsEvent.refreshContacts, "refresh_contacts"),
    (AnalyticsEvent.viewAbout, "view_about"),
    (AnalyticsEvent.requestAuthorization, "request_authorization"),
    (AnalyticsEvent.openSettings, "open_settings"),
    (AnalyticsEvent.viewPrivacyPolicy, "view_privacy_policy"),
  ])
  func parameterlessEventsMatchSchema(event: AnalyticsEvent, expectedName: String) {
    #expect(event.name == expectedName)
    #expect(event.parameters == nil)
  }
}

// MARK: - Util & Supporting Types Tests

@Suite("Supporting Types Tests")
struct SupportingTypesTests {
  @Test func appVersionReturnsVersionFromBundle() {
    let bundle = MockBundle(infoDictionary: ["CFBundleShortVersionString": "1.2.3"])
    #expect(Util.appVersion(from: bundle) == "1.2.3")
  }

  @Test func appVersionFallsBackWhenMissing() {
    let emptyBundle = MockBundle(infoDictionary: [:])
    #expect(Util.appVersion(from: emptyBundle) == "Unknown Version")

    let nilBundle = MockBundle(infoDictionary: nil)
    #expect(Util.appVersion(from: nilBundle) == "Unknown Version")
  }

  @Test func appLinksProduceValidURLs() {
    #expect(AppLinks.github?.absoluteString == "https://github.com/fsareshwala/cleandial")
    #expect(
      AppLinks.githubIssues?.absoluteString
        == "https://github.com/fsareshwala/cleandial/issues"
    )
    #expect(
      AppLinks.appStore?.absoluteString
        == "https://apps.apple.com/us/app/clean-dial/id6745625133"
    )
  }

  @Test func otherAppsExcludesCleanDialAndIncludesForecash() {
    let otherApps = DeveloperAppsCatalog.otherApps(
      excluding: DeveloperAppInfo.cleanDial.bundleIdentifier
    )
    #expect(otherApps.contains(.forecash))
    #expect(!otherApps.contains(.cleanDial))
    #expect(DeveloperAppInfo.forecash.iconUIImage != nil)
    #expect(
      DeveloperAppInfo.forecash.appStoreURL?.absoluteString
        == "https://apps.apple.com/us/app/forecash-bill-planner/id6747775439"
    )
  }

  @Test func sheetIdentifiersMatchRawValues() {
    #expect(Sheet.invalidContactsInfo.id == "invalidContactsInfo")
    #expect(Sheet.about.id == "about")
  }

  @Test func privacyPolicyContainsGitHubURL() {
    #expect(PrivacyPolicyView.policyText.contains(AppLinks.githubURLString))
  }
}
