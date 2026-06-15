import SwiftUI
import UIKit

struct NookMessageTimeline: View {
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
      NookImageUnavailableView()
    }
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
