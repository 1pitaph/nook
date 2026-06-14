import SwiftUI

struct NookIconButton: View {
  enum Style {
    case light
    case dark
    case plain
  }

  var systemName: String
  var accessibilityLabel: String
  var style: Style = .light
  var size: CGFloat = 52
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: iconSize, weight: .semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(foreground)
        .frame(width: size, height: size)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .background(background)
    .clipShape(Circle())
    .overlay(border)
    .nookShadow(style == .plain ? ShadowStyle(color: .clear, radius: 0, x: 0, y: 0) : NookTheme.tightShadow)
    .accessibilityLabel(accessibilityLabel)
  }

  private var iconSize: CGFloat {
    switch style {
    case .dark:
      19
    case .light, .plain:
      22
    }
  }

  private var foreground: Color {
    switch style {
    case .dark:
      .white
    case .light, .plain:
      NookTheme.primaryText
    }
  }

  @ViewBuilder
  private var background: some View {
    switch style {
    case .dark:
      Circle().fill(NookTheme.active)
    case .light:
      Circle().fill(NookTheme.elevatedSurface)
    case .plain:
      Circle().fill(Color.clear)
    }
  }

  @ViewBuilder
  private var border: some View {
    if style == .light {
      Circle().stroke(NookTheme.hairline, lineWidth: 0.5)
    }
  }
}
