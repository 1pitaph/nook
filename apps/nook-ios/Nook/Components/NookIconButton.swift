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
    .nookAdaptiveSurface(
      in: Circle(),
      fallbackFill: fallbackFill,
      fallbackBorder: fallbackBorder,
      fallbackShadow: fallbackShadow,
      glassTint: glassTint,
      isInteractive: style != .plain
    )
    .accessibilityLabel(accessibilityLabel)
  }

  private var iconSize: CGFloat {
    switch style {
    case .dark:
      20
    case .light, .plain:
      20
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

  private var fallbackFill: Color {
    switch style {
    case .dark:
      NookTheme.active
    case .light:
      NookTheme.elevatedSurface
    case .plain:
      .clear
    }
  }

  private var fallbackBorder: Color? {
    switch style {
    case .light:
      NookTheme.hairline
    case .dark, .plain:
      nil
    }
  }

  private var fallbackShadow: ShadowStyle? {
    switch style {
    case .light, .dark:
      NookTheme.tightShadow
    case .plain:
      nil
    }
  }

  private var glassTint: Color? {
    switch style {
    case .dark:
      NookTheme.active
    case .light, .plain:
      nil
    }
  }
}
