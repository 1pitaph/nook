import SwiftUI

struct NookSelectionToolbar: View {
  var model: NookHomeModel

  var body: some View {
    HStack(spacing: 12) {
      Text(selectionLabel)
        .font(NookFont.app(16, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.78)

      Spacer(minLength: 8)

      selectionActionButton(
        title: "Copy",
        systemName: "doc.on.doc",
        isDisabled: !model.hasSelectedEntries
      ) {
        model.copySelectedEntries()
      }

      selectionActionButton(
        title: "Delete",
        systemName: "trash",
        role: .destructive,
        isDisabled: !model.hasSelectedEntries
      ) {
        model.requestSelectedDeletion()
      }

      Button {
        model.clearSelection()
      } label: {
        Image(systemName: "checkmark")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(NookTheme.active, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Done")
    }
    .padding(.horizontal, 24)
    .padding(.top, 10)
    .padding(.bottom, 10)
    .background(NookBottomSelectionBackground())
  }

  private var selectionLabel: String {
    let count = model.selectionState.selectedCount
    return count == 1 ? "1 selected" : "\(count) selected"
  }

  private func selectionActionButton(
    title: String,
    systemName: String,
    role: ButtonRole? = nil,
    isDisabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(role: role, action: action) {
      Label(title, systemImage: systemName)
        .font(NookFont.app(14, weight: .semibold))
        .labelStyle(.iconOnly)
        .foregroundStyle(role == .destructive ? Color.red : NookTheme.primaryText)
        .frame(width: 44, height: 44)
        .nookAdaptiveSurface(
          in: Circle(),
          fallbackShadow: NookTheme.tightShadow,
          isInteractive: true
        )
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.42 : 1)
    .accessibilityLabel(title)
  }
}

private struct NookBottomSelectionBackground: View {
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
