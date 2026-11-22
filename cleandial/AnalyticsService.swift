import FirebaseAnalytics
import PhoneNumberKit

enum AnalyticsEvent: Equatable, Sendable {
  case formatContacts(PhoneNumberFormat)
  case formatTypeSaved(PhoneNumberFormat)
  case formatTypeSelected(PhoneNumberFormat)
  case viewInvalidContactsInfo
  case viewInvalidContactDetail
  case refreshContacts
  case viewAbout
  case requestAuthorization
  case openSettings
  case tapOtherApp(name: String)
  case viewPrivacyPolicy

  var name: String {
    switch self {
    case .formatContacts:
      "format_contacts"
    case .formatTypeSaved:
      AnalyticsEventSelectItem
    case .formatTypeSelected:
      "format_type_selected"
    case .viewInvalidContactsInfo:
      "view_invalid_contacts_info"
    case .viewInvalidContactDetail:
      "view_invalid_contact_detail"
    case .refreshContacts:
      "refresh_contacts"
    case .viewAbout:
      "view_about"
    case .requestAuthorization:
      "request_authorization"
    case .openSettings:
      "open_settings"
    case .tapOtherApp:
      "tap_other_app"
    case .viewPrivacyPolicy:
      "view_privacy_policy"
    }
  }

  var parameters: [String: Any]? {
    switch self {
    case .formatContacts(let format):
      ["format": format.rawValue]
    case .formatTypeSaved(let format):
      [
        AnalyticsParameterItemID: "format-type",
        AnalyticsParameterItemName: "Format Type",
        AnalyticsParameterContentType: format.analyticsName,
      ]
    case .formatTypeSelected(let format):
      ["type": format.displayName]
    case .tapOtherApp(let name):
      ["app_name": name]
    case .viewInvalidContactsInfo,
      .viewInvalidContactDetail,
      .refreshContacts,
      .viewAbout,
      .requestAuthorization,
      .openSettings,
      .viewPrivacyPolicy:
      nil
    }
  }
}

protocol AnalyticsLogging: Sendable {
  func log(_ event: AnalyticsEvent)
}

struct FirebaseAnalyticsLogger: AnalyticsLogging {
  static let shared = FirebaseAnalyticsLogger()

  func log(_ event: AnalyticsEvent) {
    Analytics.logEvent(event.name, parameters: event.parameters)
  }
}
