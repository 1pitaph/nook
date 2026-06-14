import SwiftUI

struct NookHomeView: View {
  @State private var model = NookHomeModel()

  var body: some View {
    @Bindable var model = model

    ZStack {
      NookTheme.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        NookTopBar(model: model)
          .padding(.horizontal, 24)
          .padding(.top, 10)

        NookContentCanvas(model: model)
      }
    }
    .safeAreaInset(edge: .bottom) {
      NookBottomDock(model: model)
    }
    .sheet(item: $model.activeSheet) { sheet in
      switch sheet {
      case .add:
        NookAddMenu(model: model)
          .presentationDetents([.height(310)])
          .presentationDragIndicator(.visible)
      case .status:
        NookCollectionStatusView(model: model)
          .presentationDetents([.height(380)])
          .presentationDragIndicator(.visible)
      case let .capture(message):
        NookCapturePlaceholder(message: message)
          .presentationDetents([.height(230)])
          .presentationDragIndicator(.visible)
      }
    }
    .preferredColorScheme(.light)
  }
}

private struct NookTopBar: View {
  var model: NookHomeModel

  var body: some View {
    HStack {
      Text("nook")
        .font(.system(size: 31, weight: .bold, design: .rounded))
        .foregroundStyle(NookTheme.primaryText)
        .accessibilityAddTraits(.isHeader)

      Spacer()

      NookPillButton(
        title: "\(model.entries.count)",
        systemName: model.entries.isEmpty ? "tray" : "tray.full"
      ) {
        model.openCollectionStatus()
      }
      .accessibilityLabel("Open collection status")
    }
    .frame(height: 58)
  }
}

private struct NookContentCanvas: View {
  var model: NookHomeModel

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        if model.entries.isEmpty {
          Color.clear
            .frame(height: 420)
            .accessibilityHidden(true)
        } else {
          ForEach(model.entries) { entry in
            NookEntryCard(entry: entry)
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
      .padding(.bottom, model.shouldShowSuggestions ? 196 : 116)
    }
    .scrollIndicators(.hidden)
  }
}

private struct NookEntryCard: View {
  let entry: CollectionEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: entry.source.symbolName)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .frame(width: 30, height: 30)
          .background(Color.black.opacity(0.055), in: Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(entry.title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(NookTheme.primaryText)
            .lineLimit(1)

          Text(entry.source.label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(NookTheme.secondaryText)
        }

        Spacer()
      }

      Text(entry.detail)
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(NookTheme.secondaryText)
        .lineLimit(4)
        .frame(maxWidth: .infinity, alignment: .leading)

      if !entry.tags.isEmpty {
        HStack(spacing: 8) {
          ForEach(entry.tags, id: \.self) { tag in
            Text(tag)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(NookTheme.primaryText.opacity(0.72))
              .padding(.horizontal, 9)
              .frame(height: 24)
              .background(Color.black.opacity(0.045), in: Capsule())
          }
        }
      }
    }
    .padding(16)
    .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(NookTheme.hairline, lineWidth: 0.5)
    )
  }
}

private struct NookBottomDock: View {
  var model: NookHomeModel

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
    .padding(.bottom, 12)
    .background(
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
    )
    .animation(.snappy(duration: 0.28), value: showsSuggestions)
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
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.76)

        Text(suggestion.subtitle)
          .font(.system(size: 16, weight: .regular))
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

private struct NookInputBar: View {
  @Bindable var model: NookHomeModel
  @FocusState private var isFocused: Bool
  @State private var measuredTextHeight: CGFloat = 24

  private let textFont = Font.system(size: 20, weight: .regular)
  private let controlSize: CGFloat = 56
  private let minTextHeight: CGFloat = 24
  private let maxTextHeight: CGFloat = 124

  var body: some View {
    HStack(alignment: .bottom, spacing: 10) {
      Button {
        model.openAddMenu()
      } label: {
        Image(systemName: "plus")
          .font(.system(size: 25, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .frame(width: controlSize, height: controlSize)
          .background(NookTheme.elevatedSurface, in: Circle())
          .overlay(Circle().stroke(NookTheme.hairline, lineWidth: 0.5))
          .nookShadow()
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Add source")

      HStack(alignment: .center, spacing: 10) {
        ZStack(alignment: textAlignment) {
          if model.draft.isEmpty {
            Text("Ask nook")
              .font(textFont)
              .foregroundStyle(NookTheme.tertiaryText)
              .frame(maxWidth: .infinity, alignment: .leading)
              .allowsHitTesting(false)
          }

          TextField("", text: $model.draft, axis: .vertical)
            .font(textFont)
            .foregroundStyle(NookTheme.primaryText)
            .lineLimit(1...5)
            .frame(height: textHeight, alignment: textAlignment)
            .focused($isFocused)
            .submitLabel(.send)
            .onSubmit {
              model.sendDraft()
            }
            .onChange(of: isFocused) { _, focused in
              if focused {
                model.focusDraft()
              } else {
                model.blurDraft()
              }
            }

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
        .frame(minHeight: textHeight, maxHeight: textHeight, alignment: textAlignment)
        .onPreferenceChange(NookTextHeightPreferenceKey.self) { newHeight in
          measuredTextHeight = min(max(newHeight, minTextHeight), maxTextHeight)
        }

        Button {
          model.toggleRecording()
        } label: {
          Image(systemName: model.mode == .recording ? "stop.fill" : "mic")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(model.mode == .recording ? NookTheme.primaryText : NookTheme.tertiaryText)
            .frame(width: 34, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.mode == .recording ? "Stop recording" : "Record voice note")
      }
      .padding(.leading, 18)
      .padding(.trailing, 12)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .frame(minHeight: controlSize)
      .background(
        NookTheme.elevatedSurface,
        in: RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
          .stroke(NookTheme.hairline, lineWidth: 0.5)
      )
      .nookShadow()

      NookIconButton(
        systemName: model.mode == .sending ? "hourglass" : "arrow.up",
        accessibilityLabel: "Send collection item",
        style: .dark,
        size: controlSize
      ) {
        model.sendDraft()
        isFocused = false
      }
      .disabled(model.mode == .sending)
    }
    .onChange(of: model.draft) { _, newValue in
      if !newValue.isEmpty && model.mode == .idle {
        model.mode = .editing
      }
    }
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
    28
  }
}

private struct NookTextHeightPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 24

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

private struct NookAddMenu: View {
  var model: NookHomeModel
  @Environment(\.dismiss) private var dismiss

  private let sources: [CollectionEntry.Source] = [.text, .link, .image, .voice, .file]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add to nook")
        .font(.system(size: 25, weight: .bold, design: .rounded))
        .foregroundStyle(NookTheme.primaryText)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
        ForEach(sources, id: \.self) { source in
          Button {
            dismiss()
            model.add(source: source)
          } label: {
            VStack(spacing: 10) {
              Image(systemName: source.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.055), in: Circle())

              Text(source.label)
                .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(NookTheme.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 106)
            .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
          }
          .buttonStyle(.plain)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(24)
  }
}

private struct NookCollectionStatusView: View {
  var model: NookHomeModel

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("nook")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(NookTheme.primaryText)

          Text(collectionSummary)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(NookTheme.secondaryText)
        }

        Spacer()

        Image(systemName: "sparkles")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .frame(width: 52, height: 52)
          .background(NookTheme.surface, in: Circle())
      }

      VStack(spacing: 10) {
        statusRow(title: "Captured", value: "\(model.entries.count)")
        statusRow(title: "Current source", value: model.selectedSource.label)
        statusRow(title: "Mode", value: modeLabel)
      }

      Button {
        model.activeSheet = nil
        model.openAddMenu()
      } label: {
        Label("Add something", systemImage: "plus")
          .font(.system(size: 17, weight: .semibold))
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .foregroundStyle(.white)
          .background(NookTheme.primaryText, in: Capsule())
      }
      .buttonStyle(.plain)

      Spacer(minLength: 0)
    }
    .padding(24)
  }

  private var collectionSummary: String {
    if model.entries.isEmpty {
      return "A quiet space for collecting thoughts, links, files, and voice notes."
    }
    return "Your newest captures are waiting to be shaped."
  }

  private var modeLabel: String {
    switch model.mode {
    case .idle:
      "Idle"
    case .editing:
      "Writing"
    case .sending:
      "Saving"
    case .recording:
      "Recording"
    }
  }

  private func statusRow(title: String, value: String) -> some View {
    HStack {
      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(NookTheme.secondaryText)

      Spacer()

      Text(value)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
    }
    .padding(.horizontal, 16)
    .frame(height: 50)
    .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}

private struct NookCapturePlaceholder: View {
  var message: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 18) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 42, weight: .semibold))
        .foregroundStyle(NookTheme.success)

      Text(message)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button("Done") {
        dismiss()
      }
      .font(.system(size: 17, weight: .semibold))
      .buttonStyle(.borderedProminent)
      .tint(.black)
    }
    .padding(24)
  }
}

#Preview("Empty") {
  NookHomeView()
}

#Preview("With captures") {
  NookPreviewHost(entries: CollectionEntry.samples)
}

private struct NookPreviewHost: View {
  @State private var model: NookHomeModel

  init(entries: [CollectionEntry]) {
    _model = State(initialValue: NookHomeModel(entries: entries))
  }

  var body: some View {
    ZStack {
      NookTheme.background.ignoresSafeArea()
      VStack(spacing: 0) {
        NookTopBar(model: model)
          .padding(.horizontal, 24)
          .padding(.top, 10)
        NookContentCanvas(model: model)
      }
    }
    .safeAreaInset(edge: .bottom) {
      NookBottomDock(model: model)
    }
    .preferredColorScheme(.light)
  }
}
