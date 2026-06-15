import Foundation
import UIKit

enum CollectionEntryImageResolver {
  static func data(for entry: CollectionEntry) -> Data? {
    if let imageData = entry.imageData {
      return imageData
    }

    let imageURLs = [entry.imageURL, entry.thumbnailURL].compactMap(\.self)
    for imageURL in imageURLs {
      if let data = try? Data(contentsOf: imageURL) {
        return data
      }
    }

    return nil
  }

  static func image(for entry: CollectionEntry) -> UIImage? {
    guard let data = data(for: entry) else {
      return nil
    }

    return UIImage(data: data)
  }

  static func hasImageContent(for entry: CollectionEntry) -> Bool {
    image(for: entry) != nil
  }
}
