import SwiftUI
import SwiftData
import UIKit

#if DEBUG
#Preview("Empty") {
  NookHomeView()
    .modelContainer(for: PersistedCollectionEntry.self, inMemory: true)
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
    NookHomeScaffold(model: model)
      .preferredColorScheme(.light)
  }
}

extension CollectionEntry {
  static let samples: [CollectionEntry] = [
    CollectionEntry(
      title: "Inbox structure for nook",
      detail: "Keep capture, summarize, and archive as the first three gestures.",
      tags: ["product", "draft"]
    ),
    CollectionEntry(
      title: "spotify.design",
      detail: "Designing Data Science Tools at Spotify, Part 2",
      source: .link,
      tags: ["design", "link"],
      linkURL: URL(string: "https://spotify.design/article/designing-data-science-tools-at-spotify-part-2"),
      imageData: NookPreviewImage.linkPreviewData
    ),
    CollectionEntry(
      title: "Photo from library",
      detail: "Image selected from Photos.",
      source: .image,
      tags: ["image", "photo"]
    )
  ]

  static var messageBubbleSamples: [CollectionEntry] {
    [
      CollectionEntry(
        title: "Photos from library",
        detail: "3 images selected from Photos.",
        source: .image,
        tags: ["image", "photo"],
        imageData: NookPreviewImage.stackData.first,
        imageDatas: NookPreviewImage.stackData
      ),
      CollectionEntry(
        title: "Photo from library",
        detail: "Image selected from Photos.",
        source: .image,
        tags: ["image", "photo"],
        imageData: NookPreviewImage.data
      ),
      CollectionEntry(
        title: "spotify.design",
        detail: "Designing Data Science Tools at Spotify, Part 2",
        source: .link,
        tags: ["design", "link"],
        linkURL: URL(string: "https://spotify.design/article/designing-data-science-tools-at-spotify-part-2"),
        imageData: NookPreviewImage.linkPreviewData
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

  static var stackData: [Data] {
    [
      imageData(
        background: UIColor(red: 0.78, green: 0.70, blue: 0.58, alpha: 1),
        accent: UIColor(red: 0.64, green: 0.40, blue: 0.18, alpha: 1),
        detail: UIColor(red: 0.96, green: 0.87, blue: 0.72, alpha: 1)
      ),
      imageData(
        background: UIColor(red: 0.78, green: 0.84, blue: 0.76, alpha: 1),
        accent: UIColor(red: 0.24, green: 0.42, blue: 0.30, alpha: 1),
        detail: UIColor(red: 0.94, green: 0.96, blue: 0.90, alpha: 1)
      ),
      imageData(
        background: UIColor(red: 0.89, green: 0.76, blue: 0.64, alpha: 1),
        accent: UIColor(red: 0.60, green: 0.34, blue: 0.18, alpha: 1),
        detail: UIColor(red: 0.98, green: 0.89, blue: 0.82, alpha: 1)
      )
    ]
  }

  static var linkPreviewData: Data? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 520, height: 272))
    let image = renderer.image { context in
      UIColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1).setFill()
      context.fill(CGRect(x: 0, y: 0, width: 520, height: 272))

      UIColor(red: 0.98, green: 0.17, blue: 0.12, alpha: 1).setFill()
      context.fill(CGRect(x: 0, y: 0, width: 520, height: 168))

      UIColor(red: 0.98, green: 0.40, blue: 0.30, alpha: 1).setStroke()
      context.cgContext.setLineWidth(5)
      for index in 0..<10 {
        let y = CGFloat(index) * 14 + 18
        context.cgContext.move(to: CGPoint(x: 52, y: y))
        context.cgContext.addCurve(
          to: CGPoint(x: 340, y: y + 52),
          control1: CGPoint(x: 160, y: y - 18),
          control2: CGPoint(x: 240, y: y + 70)
        )
        context.cgContext.strokePath()
      }

      UIColor.white.withAlphaComponent(0.92).setFill()
      context.cgContext.fillEllipse(in: CGRect(x: 24, y: 190, width: 24, height: 24))

      UIColor.white.withAlphaComponent(0.72).setFill()
      context.fill(CGRect(x: 64, y: 188, width: 156, height: 13))
      context.fill(CGRect(x: 24, y: 226, width: 288, height: 11))
      context.fill(CGRect(x: 24, y: 246, width: 220, height: 11))
    }
    return image.jpegData(compressionQuality: 0.88)
  }

  private static func imageData(
    background: UIColor,
    accent: UIColor,
    detail: UIColor
  ) -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 420, height: 300))
    let image = renderer.image { context in
      background.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 420, height: 300))

      detail.setFill()
      context.fill(CGRect(x: 34, y: 36, width: 352, height: 212))

      accent.setStroke()
      context.cgContext.setLineWidth(6)
      for index in 0..<7 {
        let y = CGFloat(index) * 24 + 58
        context.cgContext.move(to: CGPoint(x: 66, y: y))
        context.cgContext.addLine(to: CGPoint(x: 336, y: y + 38))
        context.cgContext.strokePath()
      }

      accent.withAlphaComponent(0.76).setFill()
      context.fill(CGRect(x: 100, y: 118, width: 170, height: 78))
    }

    return image.jpegData(compressionQuality: 0.86) ?? Data()
  }
}
#endif
