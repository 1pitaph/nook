import Foundation

struct CollectionEntry: Identifiable, Equatable {
  enum Source: String, CaseIterable, Codable {
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
  var linkURL: URL?
  var imageData: Data?
  var imageFileName: String?
  var thumbnailFileName: String?
  var imageURL: URL?
  var thumbnailURL: URL?
  var imagePixelWidth: Int?
  var imagePixelHeight: Int?
  var imageByteCount: Int?
  var imageContentType: String?

  init(
    id: UUID = UUID(),
    title: String,
    detail: String,
    source: Source = .text,
    createdAt: Date = .now,
    tags: [String] = [],
    linkURL: URL? = nil,
    imageData: Data? = nil,
    imageFileName: String? = nil,
    thumbnailFileName: String? = nil,
    imageURL: URL? = nil,
    thumbnailURL: URL? = nil,
    imagePixelWidth: Int? = nil,
    imagePixelHeight: Int? = nil,
    imageByteCount: Int? = nil,
    imageContentType: String? = nil
  ) {
    self.id = id
    self.title = title
    self.detail = detail
    self.source = source
    self.createdAt = createdAt
    self.tags = tags
    self.linkURL = linkURL
    self.imageData = imageData
    self.imageFileName = imageFileName
    self.thumbnailFileName = thumbnailFileName
    self.imageURL = imageURL
    self.thumbnailURL = thumbnailURL
    self.imagePixelWidth = imagePixelWidth
    self.imagePixelHeight = imagePixelHeight
    self.imageByteCount = imageByteCount
    self.imageContentType = imageContentType
  }
}
