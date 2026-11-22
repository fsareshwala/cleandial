import SwiftUI

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        VStack(spacing: 10) {
          Image("AppIconInApp")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(radius: 10)

          Text("Clean Dial")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Version \(Util.appVersion())")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          Form {
            Section {
              List {
                NavigationLink(destination: PrivacyPolicyView()) {
                  Label("Privacy Policy", systemImage: "questionmark.text.page")
                }
                if let appStoreURL = AppLinks.appStore {
                  ShareLink(
                    item: appStoreURL,
                    message: Text(
                      "Check out Clean Dial, the easiest way to format your contacts!"
                    )
                  ) {
                    Label("Share Clean Dial", systemImage: "square.and.arrow.up")
                  }
                }

                if let githubIssuesURL = AppLinks.githubIssues {
                  Link(destination: githubIssuesURL) {
                    Label("Report a Bug", systemImage: "exclamationmark.circle")
                  }
                }

                if let githubURL = AppLinks.github {
                  Link(destination: githubURL) {
                    Label {
                      Text("Source Code")
                        .font(.body)
                      Text(
                        "This app is fully open source. You can read the code on GitHub."
                      )
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                    } icon: {
                      Image(systemName: "curlybraces.square")
                    }
                  }
                }
              }
            }

            Section(header: Text("Other Apps from the Developer")) {
              OtherAppsView()
            }
          }
        }
        .padding(.top, 40)
        .navigationTitle("About This App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
            }
          }
        }
      }
    }
  }
}

#Preview {
  AboutView()
}
