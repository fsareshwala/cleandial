import Contacts
import ContactsUI
import PhoneNumberKit

protocol ContactStoreProviding: Sendable {
  func authorizationStatus() -> CNAuthorizationStatus
  func requestAccess() async throws -> Bool
  func fetchContacts() -> AsyncStream<Contact>
  func saveFormattedContacts(_ contacts: [Contact], toFormat format: PhoneNumberFormat) async
}

struct ContactStoreService: ContactStoreProviding {
  static let shared = ContactStoreService()

  func authorizationStatus() -> CNAuthorizationStatus {
    CNContactStore.authorizationStatus(for: .contacts)
  }

  func requestAccess() async throws -> Bool {
    return try await CNContactStore().requestAccess(for: .contacts)
  }

  func fetchContacts() -> AsyncStream<Contact> {
    AsyncStream { continuation in
      Task.detached(priority: .userInitiated) {
        let store = CNContactStore()
        let keys: [any CNKeyDescriptor] = await [
          CNContactTypeKey as any CNKeyDescriptor,
          CNContactPhoneNumbersKey as any CNKeyDescriptor,
          CNContactViewController.descriptorForRequiredKeys(),
          CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)

        do {
          try store.enumerateContacts(with: request) { contact, _ in
            for phoneNumber in contact.phoneNumbers {
              let newContact = Contact(
                deviceContact: contact,
                devicePhoneNumber: phoneNumber
              )
              continuation.yield(newContact)
            }
          }
          continuation.finish()
        } catch {
          print("Error enumerating contacts: \(error)")
          continuation.finish()
        }
      }
    }
  }

  func saveFormattedContacts(_ contacts: [Contact], toFormat format: PhoneNumberFormat) async {
    await Task.detached {
      let store = CNContactStore()
      for contact in contacts {
        let formatted = contact.formatPhoneNumber(format)
        guard
          let mutableContact = Self.makeUpdatedContact(
            from: contact.deviceContact,
            replacing: contact.devicePhoneNumber,
            with: formatted
          )
        else {
          continue
        }

        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)

        do {
          try store.execute(saveRequest)
        } catch {
          print("Error saving contact \(contact.name): \(error)")
        }
      }
    }.value
  }

  static func makeUpdatedContact(
    from deviceContact: CNContact,
    replacing originalPhoneNumber: CNLabeledValue<CNPhoneNumber>,
    with formattedNumber: String
  ) -> CNMutableContact? {
    guard let index = deviceContact.phoneNumbers.firstIndex(of: originalPhoneNumber) else {
      return nil
    }

    guard let mutableContact = deviceContact.mutableCopy() as? CNMutableContact else {
      return nil
    }

    mutableContact.phoneNumbers[index] = CNLabeledValue(
      label: originalPhoneNumber.label,
      value: CNPhoneNumber(stringValue: formattedNumber)
    )
    return mutableContact
  }
}
