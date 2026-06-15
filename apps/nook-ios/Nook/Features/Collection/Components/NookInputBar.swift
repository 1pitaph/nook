import SwiftUI

struct NookInputBar: View {
  @Bindable var model: NookHomeModel
  @FocusState private var isFocused: Bool
  @State private var measuredTextHeight: CGFloat = 24

  private let textFont = Font.system(size: 20, weight: .regular)
  private let controlSize: CGFloat = 45
  private let minTextHeight: CGFloat = 24
  private let maxTextHeight: CGFloat = 124

  var body: some View {
    inputBarContent
      .onChange(of: model.draft) { _, newValue in
        handleDraftChange(newValue)
      }
      .onChange(of: model.editingSession?.entryID) { _, entryID in
        if entryID != nil {
          isFocused = true
        }
      }
  }

  @ViewBuilder
  private var inputBarContent: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: 10) {
        inputBarControls
      }
    } else {
      inputBarControls
    }
  }

  private var inputBarControls: some View {
    HStack(alignment: .bottom, spacing: 10) {
      addSourceButton
      textEntryField
      trailingButton
    }
  }

  private var addSourceButton: some View {
    Button {
      leadingButtonAction()
    } label: {
      Image(systemName: leadingButtonSystemName)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .frame(width: controlSize, height: controlSize)
        .nookAdaptiveSurface(in: Circle(), isInteractive: true)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(leadingButtonAccessibilityLabel)
  }

  private var textEntryField: some View {
    HStack(alignment: .center, spacing: 10) {
      ZStack(alignment: textAlignment) {
        if model.draft.isEmpty {
          Text("Ask nook")
            .font(NookFont.app(20))
            .foregroundStyle(NookTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
        }

        TextField("", text: $model.draft, axis: .vertical)
          .font(textFont)
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1...5)
          .frame(maxWidth: .infinity, minHeight: textHeight, maxHeight: textHeight, alignment: textAlignment)
          .focused($isFocused)
          .submitLabel(.send)
          .onSubmit(sendSubmittedDraft)
          .onChange(of: isFocused) { _, focused in
            handleFocusChange(focused)
          }

        textHeightProbe
      }
      .frame(minHeight: textHeight, maxHeight: textHeight, alignment: textAlignment)
      .contentShape(Rectangle())
      .onTapGesture {
        isFocused = true
      }
      .onPreferenceChange(NookTextHeightPreferenceKey.self, perform: updateMeasuredTextHeight)
    }
    .padding(.leading, 18)
    .padding(.trailing, 18)
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity)
    .frame(minHeight: controlSize)
    .nookAdaptiveSurface(
      in: RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous),
      isInteractive: true
    )
  }

  private var textHeightProbe: some View {
    Text(measurementText)
      .font(textFont)
      .lineLimit(1...5)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .hidden()
      .accessibilityHidden(true)
      .background {
        GeometryReader { proxy in
          Color.clear
            .preference(key: NookTextHeightPreferenceKey.self, value: proxy.size.height)
        }
      }
  }

  private var trailingButton: some View {
    NookIconButton(
      systemName: trailingButtonSystemName,
      accessibilityLabel: trailingButtonAccessibilityLabel,
      style: .dark,
      size: controlSize
    ) {
      trailingButtonAction()
    }
    .disabled(isTrailingButtonDisabled)
  }

  private var textHeight: CGFloat {
    min(max(measuredTextHeight, minTextHeight), maxTextHeight)
  }

  private var measurementText: String {
    model.draft.isEmpty ? "Ask nook" : model.draft
  }

  private var textAlignment: Alignment {
    textHeight > minTextHeight + 2 ? .topLeading : .leading
  }

  private var inputCornerRadius: CGFloat {
    controlSize / 2
  }

  private var trailingButtonSystemName: String {
    if model.isEditingEntry {
      return "checkmark"
    }
    if model.mode == .sending {
      return "hourglass"
    }
    if shouldDismissKeyboard {
      return "keyboard.chevron.compact.down"
    }
    return "arrow.up"
  }

  private var trailingButtonAccessibilityLabel: String {
    if model.isEditingEntry {
      return "Save changes"
    }

    return shouldDismissKeyboard ? "Dismiss keyboard" : "Send collection item"
  }

  private var leadingButtonSystemName: String {
    model.isEditingEntry ? "xmark" : "plus"
  }

  private var leadingButtonAccessibilityLabel: String {
    model.isEditingEntry ? "Cancel editing" : "Add source"
  }

  private var hasDraftContent: Bool {
    !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var shouldDismissKeyboard: Bool {
    isFocused && !hasDraftContent
  }

  private var isTrailingButtonDisabled: Bool {
    if model.isEditingEntry {
      return !model.canSaveEditingDraft
    }

    return model.mode == .sending
  }

  private func handleDraftChange(_ newValue: String) {
    if !newValue.isEmpty && model.mode == .idle {
      model.mode = .editing
    }
  }

  private func handleFocusChange(_ focused: Bool) {
    if focused {
      model.focusDraft()
    } else {
      model.blurDraft()
    }
  }

  private func sendSubmittedDraft() {
    if model.isEditingEntry {
      model.saveEditingDraft()
    } else {
      model.sendDraft()
    }
  }

  private func leadingButtonAction() {
    if model.isEditingEntry {
      model.cancelEditing()
      isFocused = false
      return
    }

    model.openAddMenu()
  }

  private func trailingButtonAction() {
    if model.isEditingEntry {
      model.saveEditingDraft()
      isFocused = false
      return
    }

    if shouldDismissKeyboard {
      isFocused = false
      return
    }

    model.sendDraft()
    isFocused = false
  }

  private func updateMeasuredTextHeight(_ newHeight: CGFloat) {
    measuredTextHeight = min(max(newHeight, minTextHeight), maxTextHeight)
  }
}

private struct NookTextHeightPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 24

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
