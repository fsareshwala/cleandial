import SwiftUI

struct SelectionIndicatorView: View {
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.blue)
        } else {
            Image(systemName: "circle")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        SelectionIndicatorView(isSelected: true)
        SelectionIndicatorView(isSelected: false)
    }
}
