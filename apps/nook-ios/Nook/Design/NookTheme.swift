import SwiftUI

enum NookTheme {
  static let background = Color.white
  static let surface = Color(red: 0.985, green: 0.985, blue: 0.992)
  static let elevatedSurface = Color.white
  static let primaryText = Color(red: 0.055, green: 0.055, blue: 0.060)
  static let secondaryText = Color(red: 0.470, green: 0.470, blue: 0.510)
  static let tertiaryText = Color(red: 0.640, green: 0.640, blue: 0.670)
  static let hairline = Color.black.opacity(0.055)
  static let active = Color.black
  static let success = Color(red: 0.100, green: 0.520, blue: 0.340)
  static let note = Color(red: 0.150, green: 0.250, blue: 0.700)

  static let softShadow = ShadowStyle(
    color: Color.black.opacity(0.070),
    radius: 24,
    x: 0,
    y: 10
  )

  static let tightShadow = ShadowStyle(
    color: Color.black.opacity(0.090),
    radius: 16,
    x: 0,
    y: 8
  )
}

struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

enum NookFont {
  private static let familyName = "Sora-Regular"

  static func app(_ size: CGFloat, weight: Font.Weight? = nil) -> Font {
    let font = Font.custom(familyName, size: size)

    if let weight {
      return font.weight(weight)
    }

    return font
  }
}

extension View {
  func nookShadow(_ style: ShadowStyle = NookTheme.softShadow) -> some View {
    shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
  }

  @ViewBuilder
  func nookAdaptiveSurface<S: Shape>(
    in shape: S,
    fallbackFill: Color = NookTheme.elevatedSurface,
    fallbackBorder: Color? = NookTheme.hairline,
    fallbackShadow: ShadowStyle? = NookTheme.softShadow,
    glassTint: Color? = nil,
    isInteractive: Bool = false
  ) -> some View {
    if #available(iOS 26.0, *) {
      let baseGlass = glassTint.map { Glass.regular.tint($0) } ?? Glass.regular
      let glass = isInteractive ? baseGlass.interactive() : baseGlass

      glassEffect(glass, in: shape)
    } else {
      background(fallbackFill, in: shape)
        .overlay {
          if let fallbackBorder {
            shape.stroke(fallbackBorder, lineWidth: 0.5)
          }
        }
        .modifier(NookOptionalShadow(style: fallbackShadow))
    }
  }

  func nookCapsuleSurface() -> some View {
    nookAdaptiveSurface(in: Capsule())
  }
}

private struct NookOptionalShadow: ViewModifier {
  let style: ShadowStyle?

  @ViewBuilder
  func body(content: Content) -> some View {
    if let style {
      content.nookShadow(style)
    } else {
      content
    }
  }
}
