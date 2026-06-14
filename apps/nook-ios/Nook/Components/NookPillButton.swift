import SwiftUI

struct NookPillButton: View {
  var title: String
  var systemName: String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: systemName)
          .font(.system(size: 14, weight: .semibold))

        Text(title)
          .font(.system(size: 15, weight: .semibold))
      }
      .foregroundStyle(NookTheme.primaryText)
      .padding(.horizontal, 16)
      .frame(height: 46)
      .background(NookTheme.elevatedSurface, in: Capsule())
      .overlay(
        Capsule()
          .stroke(NookTheme.hairline, lineWidth: 0.5)
      )
      .nookShadow(NookTheme.tightShadow)
    }
    .buttonStyle(.plain)
  }
}
