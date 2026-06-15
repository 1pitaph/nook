import PhotosUI
import SwiftUI
import UIKit

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
      case .categories:
        NookCollectionCategoriesView(model: model)
          .presentationDetents([.height(620), .large])
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

      NookIconButton(
        systemName: "square.grid.2x2",
        accessibilityLabel: "Open collection categories",
        size: 52
      ) {
        model.openCollectionCategories()
      }
    }
    .frame(height: 58)
  }
}

private struct NookContentCanvas: View {
  var model: NookHomeModel

  var body: some View {
    NookMessageTimeline(
      entries: model.entries,
      topPadding: 24,
      bottomPadding: model.shouldShowSuggestions ? 196 : 116,
      emptyHeight: 420,
      scrollToLatest: true
    )
  }
}

private struct NookMessageTimeline: View {
  let entries: [CollectionEntry]
  var topPadding: CGFloat
  var bottomPadding: CGFloat
  var emptyHeight: CGFloat = 0
  var scrollToLatest = false

  private var displayEntries: [CollectionEntry] {
    Array(entries.reversed())
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollViewReader { scrollProxy in
        ScrollView {
          LazyVStack(spacing: 10) {
            if entries.isEmpty {
              Color.clear
                .frame(height: emptyHeight)
                .accessibilityHidden(true)
            } else {
              ForEach(displayEntries) { entry in
                NookMessageRow(
                  entry: entry,
                  availableWidth: geometry.size.width
                )
                .id(entry.id)
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, topPadding)
          .padding(.bottom, bottomPadding)
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.bottom)
        .onChange(of: entries.count) { _, _ in
          guard scrollToLatest, let latestID = entries.first?.id else {
            return
          }
          withAnimation(.snappy(duration: 0.28)) {
            scrollProxy.scrollTo(latestID, anchor: .bottom)
          }
        }
      }
    }
  }
}

private enum NookMessageSide {
  case incoming
  case outgoing

  var isOutgoing: Bool {
    self == .outgoing
  }
}

private struct NookMessageRow: View {
  let entry: CollectionEntry
  var availableWidth: CGFloat

  private var side: NookMessageSide {
    entry.source == .text ? .outgoing : .incoming
  }

  private var maxBubbleWidth: CGFloat {
    let widthRatio = side.isOutgoing ? 0.76 : 0.84
    let widthLimit: CGFloat = side.isOutgoing ? 500 : 560
    return min(availableWidth * widthRatio, widthLimit)
  }

  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if side.isOutgoing {
        Spacer(minLength: 48)
      }

      NookMessageBubble(entry: entry, side: side)
        .frame(maxWidth: maxBubbleWidth, alignment: side.isOutgoing ? .trailing : .leading)

      if !side.isOutgoing {
        Spacer(minLength: 48)
      }
    }
    .frame(maxWidth: .infinity, alignment: side.isOutgoing ? .trailing : .leading)
  }
}

private struct NookMessageBubble: View {
  let entry: CollectionEntry
  let side: NookMessageSide

  private var bubbleShape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      cornerRadii: RectangleCornerRadii(
        topLeading: 20,
        bottomLeading: side.isOutgoing ? 20 : 8,
        bottomTrailing: side.isOutgoing ? 8 : 20,
        topTrailing: 20
      ),
      style: .continuous
    )
  }

  var body: some View {
    Group {
      switch entry.source {
      case .text:
        NookTextBubbleContent(entry: entry)
      case .link:
        NookRichBubbleContent(entry: entry, accent: NookTheme.note) {
          NookLinkBubbleContent(entry: entry)
        }
      case .image:
        NookRichBubbleContent(entry: entry, accent: NookTheme.primaryText) {
          NookImageBubbleContent(entry: entry)
        }
      case .voice, .file:
        NookRichBubbleContent(entry: entry, accent: NookTheme.primaryText) {
          Text(entry.detail)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(NookTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .padding(entry.source == .text ? 15 : 14)
    .background(side.isOutgoing ? NookTheme.active : NookTheme.surface, in: bubbleShape)
    .overlay(
      bubbleShape
        .stroke(side.isOutgoing ? Color.clear : NookTheme.hairline, lineWidth: 0.5)
    )
    .accessibilityElement(children: .combine)
  }
}

private struct NookTextBubbleContent: View {
  let entry: CollectionEntry

  var body: some View {
    Text(entry.detail)
      .font(.system(size: 17, weight: .regular))
      .foregroundStyle(.white)
      .fixedSize(horizontal: false, vertical: true)
      .multilineTextAlignment(.leading)
  }
}

private struct NookRichBubbleContent<Content: View>: View {
  let entry: CollectionEntry
  var accent: Color
  let content: Content

  init(
    entry: CollectionEntry,
    accent: Color,
    @ViewBuilder content: () -> Content
  ) {
    self.entry = entry
    self.accent = accent
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: entry.source.symbolName)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(accent)
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
      }

      content

      NookTagRow(tags: entry.tags)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct NookLinkBubbleContent: View {
  let entry: CollectionEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.detail)
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(NookTheme.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)

      if let linkURL = entry.linkURL {
        HStack(spacing: 6) {
          Image(systemName: "link")
            .font(.system(size: 12, weight: .bold))

          Text(linkLabel(for: linkURL))
            .font(.system(size: 13, weight: .semibold))
            .lineLimit(2)
            .truncationMode(.middle)
        }
        .foregroundStyle(NookTheme.note)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private func linkLabel(for url: URL) -> String {
    if let host = url.host {
      return host.replacingOccurrences(of: "www.", with: "")
    }
    return url.absoluteString
  }
}

private struct NookImageBubbleContent: View {
  let entry: CollectionEntry

  var body: some View {
    if let imageData = entry.imageData,
       let uiImage = UIImage(data: imageData) {
      Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(NookTheme.hairline, lineWidth: 0.5)
        )
        .accessibilityLabel("Selected photo")
    } else {
      ZStack {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color.black.opacity(0.045))

        VStack(spacing: 8) {
          Image(systemName: "photo")
            .font(.system(size: 28, weight: .semibold))

          Text("Image preview unavailable")
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(NookTheme.secondaryText)
      }
      .frame(height: 160)
    }
  }
}

private struct NookTagRow: View {
  let tags: [String]

  var body: some View {
    if !tags.isEmpty {
      HStack(spacing: 8) {
        ForEach(tags, id: \.self) { tag in
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
            .frame(maxWidth: .infinity, minHeight: textHeight, maxHeight: textHeight, alignment: textAlignment)
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
        .contentShape(Rectangle())
        .onTapGesture {
          isFocused = true
        }
        .onPreferenceChange(NookTextHeightPreferenceKey.self) { newHeight in
          measuredTextHeight = min(max(newHeight, minTextHeight), maxTextHeight)
        }

      }
      .padding(.leading, 18)
      .padding(.trailing, 18)
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
        systemName: trailingButtonSystemName,
        accessibilityLabel: trailingButtonAccessibilityLabel,
        style: .dark,
        size: controlSize
      ) {
        trailingButtonAction()
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

  private var trailingButtonSystemName: String {
    if model.mode == .sending {
      return "hourglass"
    }
    if shouldDismissKeyboard {
      return "keyboard.chevron.compact.down"
    }
    return "arrow.up"
  }

  private var trailingButtonAccessibilityLabel: String {
    shouldDismissKeyboard ? "Dismiss keyboard" : "Send collection item"
  }

  private func trailingButtonAction() {
    if shouldDismissKeyboard {
      isFocused = false
      return
    }

    model.sendDraft()
    isFocused = false
  }

  private var hasDraftContent: Bool {
    !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var shouldDismissKeyboard: Bool {
    isFocused && !hasDraftContent
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
  @State private var selectedPhotoItem: PhotosPickerItem?

  private let sources: [CollectionEntry.Source] = [.text, .link, .image, .voice, .file]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add to nook")
        .font(.system(size: 25, weight: .bold, design: .rounded))
        .foregroundStyle(NookTheme.primaryText)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
        ForEach(sources, id: \.self) { source in
          if source == .image {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
              NookAddSourceTile(source: source)
            }
            .buttonStyle(.plain)
          } else {
            Button {
              dismiss()
              model.add(source: source)
            } label: {
              NookAddSourceTile(source: source)
            }
            .buttonStyle(.plain)
          }
        }
      }

      Spacer(minLength: 0)
    }
    .padding(24)
    .onChange(of: selectedPhotoItem) { _, newItem in
      guard let newItem else {
        return
      }
      dismiss()
      loadPhoto(newItem)
    }
  }

  private func loadPhoto(_ item: PhotosPickerItem) {
    Task {
      do {
        if let data = try await item.loadTransferable(type: Data.self) {
          model.addImage(data: data)
        } else {
          model.showCaptureMessage("Nook could not read that image.")
        }
      } catch {
        model.showCaptureMessage("Nook could not read that image.")
      }

      await MainActor.run {
        selectedPhotoItem = nil
      }
    }
  }
}

private struct NookAddSourceTile: View {
  let source: CollectionEntry.Source

  var body: some View {
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
}

private struct NookCollectionCategoriesView: View {
  var model: NookHomeModel
  @State private var path: [CollectionCategory] = []

  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          NookCategoryHeader(totalCount: model.entries.count)

          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CollectionCategory.allCases) { category in
              NavigationLink(value: category) {
                NookCategoryTile(
                  category: category,
                  count: model.count(for: category)
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(24)
        .padding(.top, 4)
        .padding(.bottom, 28)
      }
      .scrollIndicators(.hidden)
      .navigationDestination(for: CollectionCategory.self) { category in
        NookCategoryDetailView(model: model, category: category)
      }
    }
  }
}

private struct NookCategoryHeader: View {
  var totalCount: Int

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Collection")
          .font(.system(size: 31, weight: .bold, design: .rounded))
          .foregroundStyle(NookTheme.primaryText)

        Text(totalLabel)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(NookTheme.secondaryText)
      }

      Spacer()

      Image(systemName: "square.grid.2x2")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .frame(width: 52, height: 52)
        .background(NookTheme.surface, in: Circle())
    }
    .accessibilityElement(children: .combine)
  }

  private var totalLabel: String {
    if totalCount == 1 {
      return "1 capture sorted by category"
    }
    return "\(totalCount) captures sorted by category"
  }
}

private struct NookCategoryTile: View {
  let category: CollectionCategory
  let count: Int

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 12) {
        Image(systemName: category.symbolName)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .frame(width: 34, height: 34)
          .background(Color.black.opacity(0.055), in: Circle())

        Text(category.label)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }

      Spacer(minLength: 4)

      Text("\(count)")
        .font(.system(size: 38, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
    .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(NookTheme.hairline, lineWidth: 0.5)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(category.label), \(count)")
  }
}

private struct NookCategoryDetailView: View {
  var model: NookHomeModel
  let category: CollectionCategory

  var body: some View {
    let entries = model.entries(for: category)

    Group {
      if entries.isEmpty {
        ScrollView {
          NookCategoryEmptyState(category: category)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 360)
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
      } else {
        NookMessageTimeline(
          entries: entries,
          topPadding: 12,
          bottomPadding: 28
        )
      }
    }
    .navigationTitle(category.label)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct NookCategoryEmptyState: View {
  let category: CollectionCategory

  var body: some View {
    VStack(spacing: 14) {
      Image(systemName: category.symbolName)
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .frame(width: 62, height: 62)
        .background(NookTheme.surface, in: Circle())

      Text("No \(category.label) yet")
        .font(.system(size: 21, weight: .bold, design: .rounded))
        .foregroundStyle(NookTheme.primaryText)

      Text("New captures will appear here when they match this category.")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(NookTheme.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 280)
    }
    .accessibilityElement(children: .combine)
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

#Preview("With message bubbles") {
  NookPreviewHost(entries: CollectionEntry.messageBubbleSamples)
}

#Preview("Long content") {
  NookPreviewHost(entries: CollectionEntry.longMessageSamples)
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

private extension CollectionEntry {
  static var messageBubbleSamples: [CollectionEntry] {
    [
      CollectionEntry(
        title: "Photo from library",
        detail: "Image selected from Photos.",
        source: .image,
        tags: ["image", "photo"],
        imageData: NookPreviewImage.data
      ),
      CollectionEntry(
        title: "example.com",
        detail: "https://example.com/chat-shaped-collection",
        source: .link,
        tags: ["link", "reading"],
        linkURL: URL(string: "https://example.com/chat-shaped-collection")
      ),
      CollectionEntry(
        title: "Inbox structure for nook",
        detail: "Keep capture, summarize, and archive as the first three gestures.",
        source: .text,
        tags: ["draft", "product"]
      )
    ]
  }

  static var longMessageSamples: [CollectionEntry] {
    [
      CollectionEntry(
        title: "developer.apple.com",
        detail: "这是一条很长的链接收藏，前面有一些说明文字，后面跟着一个很长的 URL，用来检查链接气泡在小屏幕上不会把布局撑开：https://developer.apple.com/documentation/photokit/bringing_photos_picker_to_your_swiftui_app",
        source: .link,
        tags: ["link"],
        linkURL: URL(string: "https://developer.apple.com/documentation/photokit/bringing_photos_picker_to_your_swiftui_app")
      ),
      CollectionEntry(
        title: "Long mixed-language thought",
        detail: "今天先把 nook 的收集入口做得更像一段轻量对话：普通想法是我主动发出的消息，链接和图片像是被 nook 接住的外部素材。This should wrap naturally across several lines without changing the bubble alignment.",
        source: .text,
        tags: ["draft"]
      )
    ]
  }
}

private enum NookPreviewImage {
  static var data: Data? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 360, height: 240))
    let image = renderer.image { context in
      UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1).setFill()
      context.fill(CGRect(x: 0, y: 0, width: 360, height: 240))

      UIColor(red: 0.10, green: 0.52, blue: 0.34, alpha: 1).setFill()
      context.cgContext.fillEllipse(in: CGRect(x: 44, y: 48, width: 92, height: 92))

      UIColor(red: 0.15, green: 0.25, blue: 0.70, alpha: 1).setFill()
      context.cgContext.fill(
        CGRect(x: 150, y: 132, width: 164, height: 46)
      )
    }
    return image.jpegData(compressionQuality: 0.86)
  }
}
