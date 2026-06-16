import Foundation

struct CollectionImageAttachment: Equatable {
  let imageFileName: String
  let thumbnailFileName: String?
  let imageURL: URL
  let thumbnailURL: URL?
  let pixelWidth: Int?
  let pixelHeight: Int?
  let byteCount: Int
  let contentType: String?
}

struct CollectionImageAttachmentRecord: Codable, Equatable {
  let imageFileName: String
  let thumbnailFileName: String?
  let pixelWidth: Int?
  let pixelHeight: Int?
  let byteCount: Int
  let contentType: String?

  init(attachment: CollectionImageAttachment) {
    imageFileName = attachment.imageFileName
    thumbnailFileName = attachment.thumbnailFileName
    pixelWidth = attachment.pixelWidth
    pixelHeight = attachment.pixelHeight
    byteCount = attachment.byteCount
    contentType = attachment.contentType
  }
}
