import SwiftUI
import UIKit

struct NookMessageTimeline: View {
  let entries: [CollectionEntry]
  var topPadding: CGFloat
  var bottomPadding: CGFloat
  var emptyHeight: CGFloat = 0
  var scrollToLatest = false
  var selectionState = CollectionSelectionState()
  var actionHandler: (CollectionEntryAction, CollectionEntry) -> Void = { _, _ in }
  var selectionHandler: (CollectionEntry) -> Void = { _ in }

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
                  availableWidth: geometry.size.width,
                  selectionState: selectionState,
                  actionHandler: actionHandler,
                  selectionHandler: selectionHandler
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
          scrollToLatestEntry(with: scrollProxy)
        }
      }
    }
  }

  private func scrollToLatestEntry(with scrollProxy: ScrollViewProxy) {
    guard scrollToLatest, let latestID = entries.first?.id else {
      return
    }

    withAnimation(.snappy(duration: 0.28)) {
      scrollProxy.scrollTo(latestID, anchor: .bottom)
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
  var selectionState: CollectionSelectionState
  var actionHandler: (CollectionEntryAction, CollectionEntry) -> Void
  var selectionHandler: (CollectionEntry) -> Void

  private var side: NookMessageSide {
    entry.source == .text ? .outgoing : .incoming
  }

  private var maxBubbleWidth: CGFloat {
    let widthRatio = side.isOutgoing ? 0.76 : 0.84
    let widthLimit: CGFloat = side.isOutgoing ? 500 : 560
    return min(availableWidth * widthRatio, widthLimit)
  }

  var body: some View {
    HStack(alignment: .bottom, spacing: selectionState.isSelecting ? 10 : 0) {
      if side.isOutgoing {
        Spacer(minLength: 48)
      }

      if selectionState.isSelecting && !side.isOutgoing {
        selectionIndicator
      }

      interactiveBubble
        .frame(maxWidth: maxBubbleWidth, alignment: side.isOutgoing ? .trailing : .leading)

      if selectionState.isSelecting && side.isOutgoing {
        selectionIndicator
      }

      if !side.isOutgoing {
        Spacer(minLength: 48)
      }
    }
    .frame(maxWidth: .infinity, alignment: side.isOutgoing ? .trailing : .leading)
    .contentShape(Rectangle())
    .onTapGesture {
      if selectionState.isSelecting {
        selectionHandler(entry)
      }
    }
  }

  @ViewBuilder
  private var interactiveBubble: some View {
    if selectionState.isSelecting {
      bareBubble
    } else {
      NookMessageContextMenu(
        entry: entry,
        actionHandler: actionHandler
      ) {
        bareBubble
      }
    }
  }

  private var bareBubble: some View {
    NookMessageBubble(
      entry: entry,
      side: side,
      isSelected: selectionState.contains(entry)
    )
  }

  private var selectionIndicator: some View {
    Image(systemName: selectionState.contains(entry) ? "checkmark.circle.fill" : "circle")
      .font(.system(size: 22, weight: .semibold))
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(selectionState.contains(entry) ? NookTheme.note : NookTheme.tertiaryText)
      .frame(width: 28, height: 36)
      .accessibilityHidden(true)
  }
}

private struct NookMessageBubble: View {
  let entry: CollectionEntry
  let side: NookMessageSide
  var isSelected = false

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
    if entry.source == .image {
      imageBubble
    } else {
      standardBubble
    }
  }

  private var imageBubble: some View {
    NookImageBubbleContent(entry: entry)
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(isSelected ? NookTheme.note : Color.clear, lineWidth: 2)
      )
      .accessibilityElement(children: .combine)
  }

  private var standardBubble: some View {
    standardBubbleContent
      .padding(bubblePadding)
      .background(side.isOutgoing ? NookTheme.active : NookTheme.surface, in: bubbleShape)
      .clipShape(bubbleShape)
      .overlay(
        bubbleShape
          .stroke(borderColor, lineWidth: isSelected ? 2 : 0.5)
      )
      .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var standardBubbleContent: some View {
    switch entry.source {
    case .text:
      NookTextBubbleContent(entry: entry)
    case .link:
      NookLinkPreviewBubble(entry: entry)
    case .image:
      EmptyView()
    case .voice, .file:
      NookRichBubbleContent(entry: entry, accent: NookTheme.primaryText) {
        Text(entry.detail)
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(NookTheme.secondaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var borderColor: Color {
    if isSelected {
      return NookTheme.note
    }

    return side.isOutgoing ? Color.clear : NookTheme.hairline
  }

  private var bubblePadding: CGFloat {
    switch entry.source {
    case .text:
      15
    case .link:
      0
    case .image, .voice, .file:
      14
    }
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
            .font(NookFont.app(13, weight: .medium))
            .foregroundStyle(NookTheme.secondaryText)
        }
      }

      content

      NookTagRow(tags: entry.tags)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct NookImageBubbleContent: View {
  let entry: CollectionEntry

  var body: some View {
    let resolvedImages = images

    if !resolvedImages.isEmpty {
      NookImageStackPreview(images: resolvedImages)
        .accessibilityLabel(resolvedImages.count == 1 ? "Selected photo" : "\(resolvedImages.count) selected photos")
    } else {
      NookImageUnavailableView()
    }
  }

  private var images: [UIImage] {
    CollectionEntryImageResolver.images(for: entry)
  }
}

private struct NookImageStackPreview: View {
  let images: [UIImage]

  private let singleImageHeight: CGFloat = 190
  private let stackHeight: CGFloat = 224

  var body: some View {
    if let image = images.first, images.count == 1 {
      NookImageCard(image: image, cornerRadius: 16)
        .frame(maxWidth: .infinity)
        .frame(height: singleImageHeight)
    } else {
      GeometryReader { proxy in
        let cardWidth = min(proxy.size.width * 0.76, 226)
        let cardHeight = min(cardWidth * 0.74, 168)

        ZStack {
          ForEach(Array(cardLayouts.enumerated()), id: \.offset) { _, layout in
            NookImageCard(image: images[layout.imageIndex], cornerRadius: 18)
              .frame(width: cardWidth, height: cardHeight)
              .rotationEffect(layout.rotation)
              .scaleEffect(layout.scale)
              .offset(layout.offset)
              .zIndex(layout.zIndex)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(height: stackHeight)
    }
  }

  private var cardLayouts: [NookImageStackCardLayout] {
    let visibleCount = min(images.count, 3)

    switch visibleCount {
    case 2:
      return [
        NookImageStackCardLayout(
          imageIndex: 1,
          rotation: .degrees(-8),
          offset: CGSize(width: -24, height: -8),
          scale: 0.96,
          zIndex: 0
        ),
        NookImageStackCardLayout(
          imageIndex: 0,
          rotation: .degrees(4),
          offset: CGSize(width: 18, height: 14),
          scale: 1,
          zIndex: 1
        )
      ]
    default:
      return [
        NookImageStackCardLayout(
          imageIndex: 2,
          rotation: .degrees(1),
          offset: CGSize(width: 4, height: -34),
          scale: 0.92,
          zIndex: 0
        ),
        NookImageStackCardLayout(
          imageIndex: 1,
          rotation: .degrees(-10),
          offset: CGSize(width: -36, height: -2),
          scale: 0.96,
          zIndex: 1
        ),
        NookImageStackCardLayout(
          imageIndex: 0,
          rotation: .degrees(5),
          offset: CGSize(width: 22, height: 22),
          scale: 1,
          zIndex: 2
        )
      ]
    }
  }
}

private struct NookImageStackCardLayout {
  let imageIndex: Int
  let rotation: Angle
  let offset: CGSize
  let scale: CGFloat
  let zIndex: Double
}

private struct NookImageCard: View {
  let image: UIImage
  var cornerRadius: CGFloat

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .clipShape(shape)
      .overlay(
        shape
          .stroke(.white, lineWidth: 4)
      )
      .overlay(
        shape
          .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
      )
      .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 9)
  }
}

private struct NookImageUnavailableView: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color.black.opacity(0.045))

      VStack(spacing: 8) {
        Image(systemName: "photo")
          .font(.system(size: 28, weight: .semibold))

        Text("Image preview unavailable")
          .font(NookFont.app(14, weight: .semibold))
      }
      .foregroundStyle(NookTheme.secondaryText)
    }
    .frame(height: 160)
  }
}

private struct NookTagRow: View {
  let tags: [String]

  var body: some View {
    if !tags.isEmpty {
      HStack(spacing: 8) {
        ForEach(tags, id: \.self) { tag in
          Text(tag)
            .font(NookFont.app(12, weight: .semibold))
            .foregroundStyle(NookTheme.primaryText.opacity(0.72))
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(Color.black.opacity(0.045), in: Capsule())
        }
      }
    }
  }
}
