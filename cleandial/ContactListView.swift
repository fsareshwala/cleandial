import SwiftUI

struct ContactListView: View {
  @State private var viewModel = ContactListViewModel()
  @State private var activeSheet: Sheet?
  @State private var isFormattingInProgress: Bool = false
  @State private var selectedInvalidContact: Contact?

  @Environment(\.scenePhase) private var scenePhase

  private func doFormat() {
    FirebaseAnalyticsLogger.shared.log(.formatContacts(viewModel.selectedFormatType))
    isFormattingInProgress = true
    Task {
      await viewModel.saveContacts()
      isFormattingInProgress = false
    }
  }

  private var invalidContactsSection: some View {
    Section(
      header: HStack {
        Text("Invalid Contacts")
        Button(action: {
          activeSheet = .invalidContactsInfo
          FirebaseAnalyticsLogger.shared.log(.viewInvalidContactsInfo)
        }) {
          Image(systemName: "info.circle")
            .foregroundStyle(.blue)
        }
      }
    ) {
      ForEach(viewModel.invalidContacts) { contact in
        Button(action: {
          selectedInvalidContact = contact
          FirebaseAnalyticsLogger.shared.log(.viewInvalidContactDetail)
        }) {
          InvalidContactRowView(contact: contact)
        }
      }
    }
  }

  private var formattingOverlay: some View {
    VStack {
      ProgressView()
        .controlSize(.large)
      Text("Formatting...")
        .padding(.top)
    }
    .padding(30)
    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
    .shadow(radius: 10)
  }

  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Format Type")) {
          FormatTypeList(selectedFormatType: $viewModel.selectedFormatType)
        }

        Section(header: Text("Contacts")) {
          if !viewModel.anyContactNeedsFormatting() {
            ContentUnavailableView {
              Label("No Contacts", systemImage: "person.crop.circle.badge.checkmark")
            } description: {
              Text("All contact phone numbers are formatted correctly")
            }
          }

          ForEach($viewModel.validContacts) { $contact in
            if let formatted = contact.formattedPhoneNumberIfNeeded(
              for: viewModel.selectedFormatType
            ) {
              ContactView(
                isChecked: $contact.isChecked,
                name: contact.name,
                phoneNumber: formatted,
                originalPhoneNumber: contact.phoneNumber,
                phoneNumberLabel: contact.phoneNumberLabel
              )
            }
          }
        }

        if !viewModel.invalidContacts.isEmpty {
          invalidContactsSection
        }
      }
      .sheet(item: $selectedInvalidContact) { contact in
        ContactDetailView(contact: contact.deviceContact)
      }
      .navigationTitle("Clean Dial")
      .navigationBarTitleDisplayMode(.inline)
      .refreshable {
        FirebaseAnalyticsLogger.shared.log(.refreshContacts)
        await viewModel.getContacts()
      }
      .onChange(of: scenePhase) {
        if scenePhase == .active {
          Task {
            await viewModel.getContacts()
          }
        }
      }
      .sheet(item: $activeSheet) { sheet in sheet.view }
      .disabled(isFormattingInProgress)
      .overlay {
        if isFormattingInProgress {
          formattingOverlay
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: {
            activeSheet = .about
            FirebaseAnalyticsLogger.shared.log(.viewAbout)
          }) {
            Image(systemName: "info.circle")
          }
        }
        ToolbarItem(placement: .bottomBar) { Spacer() }

        if viewModel.anyContactNeedsFormatting() {
          ToolbarItem(placement: .bottomBar) {
            Button(action: { doFormat() }) {
              Image(systemName: "person.crop.circle.badge.checkmark")
            }
            .foregroundStyle(.blue)
          }
        }
      }
    }
  }
}
