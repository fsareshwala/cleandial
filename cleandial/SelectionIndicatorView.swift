import SwiftUI

struct SelectionIndicatorView: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isSelected ? .blue : .gray)
    }
}

#Preview {
    HStack(spacing: 16) {
        SelectionIndicatorView(isSelected: true)
        SelectionIndicatorView(isSelected: false)
    }
}
