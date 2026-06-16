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
  var imageAttachmentsData: Data?
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
    imageAttachmentsData = Self.encodedImageAttachments(entry.imageAttachments)
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
    imageAttachmentsData = Self.encodedImageAttachments(entry.imageAttachments)
    imageFileName = entry.imageFileName
    thumbnailFileName = entry.thumbnailFileName
    imagePixelWidth = entry.imagePixelWidth
    imagePixelHeight = entry.imagePixelHeight
    imageByteCount = entry.imageByteCount
    imageContentType = entry.imageContentType
  }

  func entry(attachmentStore: CollectionAttachmentStore) -> CollectionEntry {
    let legacyAttachment = attachmentStore.attachment(
      imageFileName: imageFileName,
      thumbnailFileName: thumbnailFileName,
      pixelWidth: imagePixelWidth,
      pixelHeight: imagePixelHeight,
      byteCount: imageByteCount,
      contentType: imageContentType
    )
    let attachments = Self.decodedImageAttachments(
      imageAttachmentsData,
      attachmentStore: attachmentStore
    )
    let imageAttachments = attachments.isEmpty ? legacyAttachment.map { [$0] } ?? [] : attachments
    let primaryAttachment = imageAttachments.first ?? legacyAttachment

    return CollectionEntry(
      id: id,
      title: title,
      detail: detail,
      source: CollectionEntry.Source(rawValue: sourceRawValue) ?? .text,
      createdAt: createdAt,
      tags: tags,
      linkURL: linkURL,
      imageAttachments: imageAttachments,
      imageFileName: primaryAttachment?.imageFileName ?? imageFileName,
      thumbnailFileName: primaryAttachment?.thumbnailFileName ?? thumbnailFileName,
      imageURL: primaryAttachment?.imageURL,
      thumbnailURL: primaryAttachment?.thumbnailURL,
      imagePixelWidth: primaryAttachment?.pixelWidth ?? imagePixelWidth,
      imagePixelHeight: primaryAttachment?.pixelHeight ?? imagePixelHeight,
      imageByteCount: primaryAttachment?.byteCount ?? imageByteCount,
      imageContentType: primaryAttachment?.contentType ?? imageContentType
    )
  }

  private static func encodedImageAttachments(_ attachments: [CollectionImageAttachment]) -> Data? {
    guard !attachments.isEmpty else {
      return nil
    }

    let records = attachments.map(CollectionImageAttachmentRecord.init)
    return try? JSONEncoder().encode(records)
  }

  private static func decodedImageAttachments(
    _ data: Data?,
    attachmentStore: CollectionAttachmentStore
  ) -> [CollectionImageAttachment] {
    guard let data,
          let records = try? JSONDecoder().decode([CollectionImageAttachmentRecord].self, from: data) else {
      return []
    }

    return records.map { attachmentStore.attachment(for: $0) }
  }
}
