import SwiftUI

struct LogoHeaderView: View {
  var body: some View {
    IconHeaderView(
      systemImage: "person.crop.circle.badge.checkmark",
      title: "Clean Dial",
      symbolRenderingMode: .multicolor,
      titlePaddingEdges: .bottom
    )
  }
}

#Preview {
  LogoHeaderView()
}
