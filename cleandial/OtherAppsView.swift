import SwiftUI

struct AppInfo: Identifiable, Equatable {
  let iconName: String
  let appName: String
  let description: String
  let appStoreLink: String

  var id: String { appName }

  var appStoreURL: URL? {
    URL(string: appStoreLink)
  }

  static let forecash = AppInfo(
    iconName: "forecash",
    appName: "Forecash",
    description:
      "Plan bill pay dates, forecast your finances. Project your future balance so you can plan ahead.",
    appStoreLink: "https://apps.apple.com/us/app/forecash-bill-planner/id6747775439"
  )
}

struct OtherAppsView: View {
  @Environment(\.openURL) private var openURL
  let app: AppInfo

  init(app: AppInfo = .forecash) {
    self.app = app
  }

  var body: some View {
    Button(action: {
      FirebaseAnalyticsLogger.shared.log(.tapOtherApp(name: app.appName))
      if let url = app.appStoreURL {
        openURL(url)
      }
    }) {
      HStack(spacing: 15) {
        Image(app.iconName)
          .resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .foregroundStyle(.tint)
          .clipShape(.rect(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 4) {
          Text(app.appName)
            .font(.headline)

          Text(app.description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
  }
}

#Preview {
  OtherAppsView()
}
