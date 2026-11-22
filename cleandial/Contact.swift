import Contacts
import PhoneNumberKit

extension PhoneNumberFormat {
    static let allOptions: [PhoneNumberFormat] = [.international, .national, .e164]

    var displayName: String {
        switch self {
        case .international:
            "International"
        case .national:
            "National"
        case .e164:
            "e.164"
        }
    }

    var analyticsName: String {
        switch self {
        case .e164:
            "E164"
        case .international:
            "International"
        case .national:
            "National"
        }
    }
}

struct Contact: Identifiable, @unchecked Sendable {
    static let sharedPhoneNumberUtility = PhoneNumberUtility()

    let id = UUID()
    private let phoneNumberUtility: PhoneNumberUtility

    let deviceContact: CNContact
    let devicePhoneNumber: CNLabeledValue<CNPhoneNumber>
    let parsedPhoneNumber: PhoneNumber

    var isChecked: Bool = true

    var name: String {
        CNContactFormatter.string(from: deviceContact, style: .fullName) ?? "Unknown name"
    }

    var phoneNumberLabel: String {
        guard let label = devicePhoneNumber.label else { return "" }
        return CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
    }

    var phoneNumber: String {
        devicePhoneNumber.value.stringValue
    }

    init(
        deviceContact: CNContact,
        devicePhoneNumber: CNLabeledValue<CNPhoneNumber>,
        isChecked: Bool = true,
        phoneNumberUtility: PhoneNumberUtility = Contact.sharedPhoneNumberUtility
    ) {
        self.deviceContact = deviceContact
        self.devicePhoneNumber = devicePhoneNumber
        self.isChecked = isChecked
        self.phoneNumberUtility = phoneNumberUtility

        do {
            parsedPhoneNumber = try phoneNumberUtility.parse(
                devicePhoneNumber.value.stringValue,
                ignoreType: true
            )
        } catch {
            parsedPhoneNumber = PhoneNumber.notPhoneNumber()
        }
    }

    var hasValidPhoneNumber: Bool {
        parsedPhoneNumber != PhoneNumber.notPhoneNumber()
    }

    func formattedPhoneNumberIfNeeded(for format: PhoneNumberFormat) -> String? {
        guard hasValidPhoneNumber else {
            return nil
        }

        let formatted = formatPhoneNumber(format)
        return phoneNumber == formatted ? nil : formatted
    }

    func needsFormatting(toFormat: PhoneNumberFormat) -> Bool {
        formattedPhoneNumberIfNeeded(for: toFormat) != nil
    }

    func formatPhoneNumber(_ toFormat: PhoneNumberFormat) -> String {
        phoneNumberUtility.format(parsedPhoneNumber, toType: toFormat)
    }
}
