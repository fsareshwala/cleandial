import Foundation

enum Util {
  static func appVersion(from bundle: Bundle = .main) -> String {
    bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
  }
}

enum AppLinks {
  static let githubURLString = "https://github.com/fsareshwala/cleandial"
  static let appStoreURLString = "https://apps.apple.com/us/app/clean-dial/id6745625133"

  static var github: URL? {
    URL(string: githubURLString)
  }

  static var githubIssues: URL? {
    URL(string: "\(githubURLString)/issues")
  }

  static var appStore: URL? {
    URL(string: appStoreURLString)
  }
}
