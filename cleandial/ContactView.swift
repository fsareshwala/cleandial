import SwiftUI

struct ContactView: View {
  @Binding var isChecked: Bool
  let name: String
  let phoneNumber: String
  let originalPhoneNumber: String
  let phoneNumberLabel: String

  var body: some View {
    HStack {
      Button(action: { isChecked.toggle() }) {
        SelectionIndicatorView(isSelected: isChecked)
          .padding(.trailing)
      }

      VStack(alignment: .leading) {
        HStack {
          Text(name)
          Spacer()
          Text(phoneNumber)
            .font(.footnote)
        }
        HStack {
          Text(phoneNumberLabel)
          Spacer()
          Text(originalPhoneNumber)
            .strikethrough()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
  }
}

struct InvalidContactRowView: View {
  let contact: Contact

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(contact.name)
          .foregroundStyle(.primary)
        Spacer()
        Text(contact.phoneNumber)
          .font(.footnote)
          .foregroundStyle(.primary)
      }
      HStack {
        Spacer()
        Text(contact.phoneNumberLabel)
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
  }
}
