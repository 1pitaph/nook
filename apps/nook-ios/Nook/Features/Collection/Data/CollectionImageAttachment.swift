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
