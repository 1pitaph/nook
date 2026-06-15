import SwiftUI
import UIKit

struct NookLinkPreviewBubble: View {
  let entry: CollectionEntry

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @StateObject private var loader = NookLinkPreviewLoader()

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      NookLinkPreviewArtwork(
        image: previewImage,
        host: siteName,
        height: artworkHeight
      )

      VStack(alignment: .leading, spacing: 8) {
        NookLinkPreviewSiteRow(
          icon: loader.preview.icon,
          siteName: siteName
        )

        Text(titleText)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
          .fixedSize(horizontal: false, vertical: true)

        if let summaryText {
          Text(summaryText)
            .font(.system(size: 13.5, weight: .regular))
            .foregroundStyle(NookTheme.secondaryText)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 11)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task(id: entry.linkURL) {
      await loader.load(for: entry.linkURL)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  private var previewImage: UIImage? {
    loader.preview.image ?? CollectionEntryImageResolver.image(for: entry)
  }

  private var artworkHeight: CGFloat {
    dynamicTypeSize.isAccessibilitySize ? 112 : 154
  }

  private var siteName: String {
    loader.preview.siteName.nonEmpty
      ?? entry.linkURL.flatMap(NookLinkPreviewFormatting.siteName(for:))
      ?? entry.title.nonEmpty
      ?? "Website"
  }

  private var titleText: String {
    loader.preview.title.nonEmpty
      ?? NookLinkPreviewFormatting.noteText(in: entry.detail, excluding: entry.linkURL)
      ?? entry.linkURL?.absoluteString
      ?? entry.detail
  }

  private var summaryText: String? {
    let summary = loader.preview.summary.nonEmpty
    guard summary != titleText else {
      return nil
    }
    return summary
  }

  private var accessibilityLabel: Text {
    var parts = [siteName, titleText]
    if let summaryText {
      parts.append(summaryText)
    }
    return Text(parts.joined(separator: ", "))
  }
}

private struct NookLinkPreviewArtwork: View {
  var image: UIImage?
  var host: String
  var height: CGFloat

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        NookLinkPreviewPlaceholder(host: host)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipped()
    .accessibilityHidden(true)
  }
}

private struct NookLinkPreviewPlaceholder: View {
  var host: String

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      LinearGradient(
        colors: [
          Color(red: 0.965, green: 0.975, blue: 0.990),
          Color(red: 0.960, green: 0.940, blue: 0.900),
          Color(red: 0.900, green: 0.935, blue: 0.970)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(alignment: .leading, spacing: 10) {
        Image(systemName: "link")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(NookTheme.note)
          .frame(width: 40, height: 40)
          .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

        Text(host)
          .font(NookFont.app(13, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
      .padding(14)

      VStack(spacing: 8) {
        Capsule()
          .fill(NookTheme.note.opacity(0.22))
          .frame(width: 132, height: 9)
        Capsule()
          .fill(NookTheme.success.opacity(0.18))
          .frame(width: 96, height: 9)
        Capsule()
          .fill(Color.black.opacity(0.10))
          .frame(width: 168, height: 9)
      }
      .rotationEffect(.degrees(-12))
      .offset(x: 150, y: -72)
    }
  }
}

private struct NookLinkPreviewSiteRow: View {
  var icon: UIImage?
  var siteName: String

  var body: some View {
    HStack(spacing: 7) {
      NookLinkPreviewIcon(image: icon, siteName: siteName)

      Text(siteName)
        .font(NookFont.app(12, weight: .semibold))
        .foregroundStyle(NookTheme.note)
        .lineLimit(1)
        .truncationMode(.tail)
        .minimumScaleFactor(0.82)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct NookLinkPreviewIcon: View {
  var image: UIImage?
  var siteName: String

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(NookTheme.note.opacity(0.10))

          Text(fallbackInitial)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(NookTheme.note)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
      }
    }
    .frame(width: 20, height: 20)
    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 5, style: .continuous)
        .stroke(NookTheme.hairline, lineWidth: 0.5)
    )
    .accessibilityHidden(true)
  }

  private var fallbackInitial: String {
    siteName
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .first
      .map { String($0).uppercased() }
      ?? "L"
  }
}
