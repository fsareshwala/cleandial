import SwiftUI

struct IconHeaderView: View {
  let systemImage: String
  let title: String
  var symbolRenderingMode: SymbolRenderingMode? = nil
  var tintColor: Color? = nil
  var titlePaddingEdges: Edge.Set = .bottom

  var body: some View {
    VStack {
      iconImage
      Text(title)
        .font(.largeTitle)
        .bold()
        .padding(titlePaddingEdges)
    }
  }

  @ViewBuilder
  private var iconImage: some View {
    let baseImage = Image(systemName: systemImage)
      .symbolRenderingMode(symbolRenderingMode)
      .resizable()
      .scaledToFit()
      .frame(width: 85, height: 85)

    if let tintColor {
      baseImage.foregroundStyle(tintColor)
    } else {
      baseImage
    }
  }
}

#Preview {
  IconHeaderView(
    systemImage: "person.crop.circle.badge.checkmark",
    title: "Clean Dial",
    symbolRenderingMode: .multicolor
  )
}
