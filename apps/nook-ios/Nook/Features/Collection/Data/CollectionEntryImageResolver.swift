import Foundation
import UIKit

enum CollectionEntryImageResolver {
  static func data(for entry: CollectionEntry) -> Data? {
    dataItems(for: entry).first
  }

  static func dataItems(for entry: CollectionEntry) -> [Data] {
    if !entry.imageDatas.isEmpty {
      return entry.imageDatas
    }

    if let imageData = entry.imageData {
      return [imageData]
    }

    if !entry.imageAttachments.isEmpty {
      return entry.imageAttachments.compactMap { attachment in
        data(for: attachment)
      }
    }

    let imageURLs = [entry.imageURL, entry.thumbnailURL].compactMap(\.self)
    for imageURL in imageURLs {
      if let data = try? Data(contentsOf: imageURL) {
        return [data]
      }
    }

    return []
  }

  static func image(for entry: CollectionEntry) -> UIImage? {
    guard let data = data(for: entry) else {
      return nil
    }

    return UIImage(data: data)
  }

  static func images(for entry: CollectionEntry) -> [UIImage] {
    dataItems(for: entry).compactMap { UIImage(data: $0) }
  }

  static func hasImageContent(for entry: CollectionEntry) -> Bool {
    !images(for: entry).isEmpty
  }

  private static func data(for attachment: CollectionImageAttachment) -> Data? {
    let imageURLs = [attachment.imageURL, attachment.thumbnailURL].compactMap(\.self)
    for imageURL in imageURLs {
      if let data = try? Data(contentsOf: imageURL) {
        return data
      }
    }

    return nil
  }
}
