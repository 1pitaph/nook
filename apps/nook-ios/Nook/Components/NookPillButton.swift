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
          .font(NookFont.app(15, weight: .semibold))
      }
      .foregroundStyle(NookTheme.primaryText)
      .padding(.horizontal, 16)
      .frame(height: 46)
      .nookAdaptiveSurface(
        in: Capsule(),
        fallbackShadow: NookTheme.tightShadow,
        isInteractive: true
      )
    }
    .buttonStyle(.plain)
  }
}
