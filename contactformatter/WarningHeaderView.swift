import SwiftUI

struct WarningHeaderView: View {
    var body: some View {
        IconHeaderView(
            systemImage: "exclamationmark.triangle",
            title: "Warning",
            tintColor: .yellow,
            titlePaddingEdges: .all
        )
    }
}

#Preview {
    WarningHeaderView()
}
