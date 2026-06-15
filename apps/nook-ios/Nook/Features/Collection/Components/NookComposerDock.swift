import SwiftUI
import UIKit

struct NookBottomDock: View {
  var model: NookHomeModel

  @State private var isKeyboardVisible = false

  private let keyboardGap: CGFloat = 10

  var body: some View {
    let showsSuggestions = model.shouldShowSuggestions

    VStack(spacing: 14) {
      NookSuggestionRow(model: model)
        .frame(height: showsSuggestions ? 88 : 0)
        .opacity(showsSuggestions ? 1 : 0)
        .scaleEffect(showsSuggestions ? 1 : 0.98, anchor: .bottom)
        .allowsHitTesting(showsSuggestions)
        .clipped()

      NookInputBar(model: model)
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, isKeyboardVisible ? keyboardGap : 0)
    .background(NookBottomDockBackground())
    .animation(.snappy(duration: 0.28), value: showsSuggestions)
    .animation(.snappy(duration: 0.22), value: isKeyboardVisible)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
      isKeyboardVisible = NookKeyboardState.isVisible(notification)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      isKeyboardVisible = false
    }
  }
}

private struct NookBottomDockBackground: View {
  var body: some View {
    LinearGradient(
      colors: [
        Color.white.opacity(0.0),
        Color.white.opacity(0.96),
        Color.white
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}

private enum NookKeyboardState {
  @MainActor
  static func isVisible(_ notification: Notification) -> Bool {
    guard
      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
      let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
    else {
      return false
    }

    return frame.minY < windowScene.screen.bounds.maxY
  }
}

private struct NookSuggestionRow: View {
  var model: NookHomeModel

  var body: some View {
    GeometryReader { proxy in
      let cardWidth = max(154, min(176, (proxy.size.width - 12) / 2))

      ScrollView(.horizontal) {
        HStack(spacing: 12) {
          ForEach(model.suggestions.prefix(4)) { suggestion in
            NookSuggestionCard(suggestion: suggestion, width: cardWidth) {
              model.apply(suggestion)
            }
          }
        }
        .scrollTargetLayout()
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned)
    }
    .frame(height: 88)
  }
}

private struct NookSuggestionCard: View {
  let suggestion: NookSuggestion
  var width: CGFloat
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 4) {
        Text(suggestion.title)
          .font(NookFont.app(17, weight: .bold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.76)

        Text(suggestion.subtitle)
          .font(NookFont.app(16))
          .foregroundStyle(NookTheme.secondaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.76)
      }
      .padding(.horizontal, 16)
      .frame(width: width, height: 82, alignment: .leading)
      .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 21, style: .continuous)
          .stroke(NookTheme.hairline, lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(suggestion.title), \(suggestion.subtitle)")
  }
}
