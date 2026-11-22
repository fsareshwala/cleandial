import Contacts
import Observation
import PhoneNumberKit

@MainActor
@Observable
final class ContactListViewModel {
    var validContacts: [Contact] = []
    var invalidContacts: [Contact] = []
    var selectedFormatType: PhoneNumberFormat = .international

    private let contactStore: any ContactStoreProviding
    private let analytics: any AnalyticsLogging
    private var isFetchingContacts = false
    private let batchSize: Int

    init(
        contactStore: any ContactStoreProviding = ContactStoreService.shared,
        analytics: any AnalyticsLogging = FirebaseAnalyticsLogger.shared,
        batchSize: Int = 50,
        loadOnInit: Bool = true
    ) {
        self.contactStore = contactStore
        self.analytics = analytics
        self.batchSize = batchSize

        if loadOnInit {
            Task {
                await getContacts()
            }
        }
    }

    func anyContactNeedsFormatting() -> Bool {
        validContacts.contains { $0.needsFormatting(toFormat: selectedFormatType) }
    }

    func saveContacts() async {
        guard anyContactNeedsFormatting() else { return }

        let formatType = selectedFormatType
        let contactsToFormat = validContacts.filter {
            $0.isChecked && $0.needsFormatting(toFormat: formatType)
        }

        guard !contactsToFormat.isEmpty else { return }

        await contactStore.saveFormattedContacts(contactsToFormat, toFormat: formatType)

        analytics.log(.formatTypeSaved(formatType))
        await getContacts()
    }

    func getContacts() async {
        guard !isFetchingContacts else { return }
        isFetchingContacts = true
        defer { isFetchingContacts = false }

        switch contactStore.authorizationStatus() {
        case .authorized, .limited:
            await fetchContacts()
        case .notDetermined:
            if await requestAuthorization() {
                await fetchContacts()
            }
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    private func requestAuthorization() async -> Bool {
        do {
            return try await contactStore.requestAccess()
        } catch {
            print("Error requesting contact access: \(error)")
            return false
        }
    }

    private func fetchContacts() async {
        validContacts = []
        invalidContacts = []

        var contactBatch: [Contact] = []
        for await contact in contactStore.fetchContacts() {
            contactBatch.append(contact)
            if contactBatch.count >= batchSize {
                appendContacts(contactBatch)
                contactBatch.removeAll(keepingCapacity: true)
            }
        }

        if !contactBatch.isEmpty {
            appendContacts(contactBatch)
        }

        validContacts.sort { $0.name < $1.name }
        invalidContacts.sort { $0.name < $1.name }
    }

    private func appendContacts(_ batch: [Contact]) {
        for contact in batch {
            if contact.hasValidPhoneNumber {
                validContacts.append(contact)
            } else {
                invalidContacts.append(contact)
            }
        }
    }
}
