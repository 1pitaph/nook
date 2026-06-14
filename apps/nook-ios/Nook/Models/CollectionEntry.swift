import Foundation

struct CollectionEntry: Identifiable, Equatable {
  enum Source: String, CaseIterable {
    case text
    case link
    case image
    case voice
    case file

    var label: String {
      switch self {
      case .text:
        "Text"
      case .link:
        "Link"
      case .image:
        "Image"
      case .voice:
        "Voice"
      case .file:
        "File"
      }
    }

    var symbolName: String {
      switch self {
      case .text:
        "text.quote"
      case .link:
        "link"
      case .image:
        "photo"
      case .voice:
        "waveform"
      case .file:
        "doc"
      }
    }
  }

  let id: UUID
  var title: String
  var detail: String
  var source: Source
  var createdAt: Date
  var tags: [String]

  init(
    id: UUID = UUID(),
    title: String,
    detail: String,
    source: Source = .text,
    createdAt: Date = .now,
    tags: [String] = []
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.source = source
    self.createdAt = createdAt
    self.tags = tags
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
      title: "Article to read later",
      detail: "https://example.com/chat-shaped-collection",
      source: .link,
      tags: ["reading"]
    )
  ]
}
