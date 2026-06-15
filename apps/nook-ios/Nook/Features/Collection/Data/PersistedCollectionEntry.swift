import Foundation
import SwiftData

@Model
final class PersistedCollectionEntry {
  @Attribute(.unique) var id: UUID
  var title: String
  var detail: String
  var sourceRawValue: String
  var createdAt: Date
  var tags: [String]
  var linkURL: URL?
  var imageFileName: String?
  var thumbnailFileName: String?
  var imagePixelWidth: Int?
  var imagePixelHeight: Int?
  var imageByteCount: Int?
  var imageContentType: String?

  init(entry: CollectionEntry) {
    id = entry.id
    title = entry.title
    detail = entry.detail
    sourceRawValue = entry.source.rawValue
    createdAt = entry.createdAt
    tags = entry.tags
    linkURL = entry.linkURL
    imageFileName = entry.imageFileName
    thumbnailFileName = entry.thumbnailFileName
    imagePixelWidth = entry.imagePixelWidth
    imagePixelHeight = entry.imagePixelHeight
    imageByteCount = entry.imageByteCount
    imageContentType = entry.imageContentType
  }

  func update(with entry: CollectionEntry) {
    title = entry.title
    detail = entry.detail
    sourceRawValue = entry.source.rawValue
    createdAt = entry.createdAt
    tags = entry.tags
    linkURL = entry.linkURL
    imageFileName = entry.imageFileName
    thumbnailFileName = entry.thumbnailFileName
    imagePixelWidth = entry.imagePixelWidth
    imagePixelHeight = entry.imagePixelHeight
    imageByteCount = entry.imageByteCount
    imageContentType = entry.imageContentType
  }

  func entry(attachmentStore: CollectionAttachmentStore) -> CollectionEntry {
    let attachment = attachmentStore.attachment(
      imageFileName: imageFileName,
      thumbnailFileName: thumbnailFileName,
      pixelWidth: imagePixelWidth,
      pixelHeight: imagePixelHeight,
      byteCount: imageByteCount,
      contentType: imageContentType
    )

    return CollectionEntry(
      id: id,
      title: title,
      detail: detail,
      source: CollectionEntry.Source(rawValue: sourceRawValue) ?? .text,
      createdAt: createdAt,
      tags: tags,
      linkURL: linkURL,
      imageFileName: imageFileName,
      thumbnailFileName: thumbnailFileName,
      imageURL: attachment?.imageURL,
      thumbnailURL: attachment?.thumbnailURL,
      imagePixelWidth: imagePixelWidth,
      imagePixelHeight: imagePixelHeight,
      imageByteCount: imageByteCount,
      imageContentType: imageContentType
    )
  }
}
