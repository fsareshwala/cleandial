import PhoneNumberKit
import SwiftUI

struct FormatTypeList: View {
  @Binding var selectedFormatType: PhoneNumberFormat

  var body: some View {
    ForEach(PhoneNumberFormat.allOptions, id: \.self) { formatType in
      HStack {
        Button(action: {
          selectedFormatType = formatType
          FirebaseAnalyticsLogger.shared.log(.formatTypeSelected(formatType))
        }) {
          SelectionIndicatorView(isSelected: selectedFormatType == formatType)
        }

        Text(formatType.displayName)
          .font(.callout)
      }
    }
  }
}
