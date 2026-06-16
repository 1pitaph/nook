import Foundation
import ImageIO
import UniformTypeIdentifiers
import UIKit

struct CollectionAttachmentStore {
  private let fileManager: FileManager
  private let appSupportDirectory: URL
  private let cachesDirectory: URL

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    appSupportDirectory = URL.applicationSupportDirectory
      .appending(path: "Nook", directoryHint: .isDirectory)
      .appending(path: "Attachments", directoryHint: .isDirectory)
    cachesDirectory = URL.cachesDirectory
      .appending(path: "Nook", directoryHint: .isDirectory)
      .appending(path: "Thumbnails", directoryHint: .isDirectory)
  }

  func saveImage(_ data: Data) throws -> CollectionImageAttachment {
    try fileManager.createDirectory(
      at: appSupportDirectory,
      withIntermediateDirectories: true
    )
    try fileManager.createDirectory(
      at: cachesDirectory,
      withIntermediateDirectories: true
    )

    let metadata = imageMetadata(for: data)
    let id = UUID().uuidString
    let imageFileName = "\(id).\(metadata.fileExtension)"
    let imageURL = appSupportDirectory.appending(path: imageFileName)
    try data.write(to: imageURL, options: .atomic)
    try protectFile(at: imageURL)

    let thumbnailFileName = "\(id)-thumb.jpg"
    let thumbnailURL = cachesDirectory.appending(path: thumbnailFileName)
    let savedThumbnailURL: URL?
    if let thumbnailData = thumbnailData(from: data) {
      try thumbnailData.write(to: thumbnailURL, options: .atomic)
      savedThumbnailURL = thumbnailURL
    } else {
      savedThumbnailURL = nil
    }

    return CollectionImageAttachment(
      imageFileName: imageFileName,
      thumbnailFileName: savedThumbnailURL == nil ? nil : thumbnailFileName,
      imageURL: imageURL,
      thumbnailURL: savedThumbnailURL,
      pixelWidth: metadata.pixelWidth,
      pixelHeight: metadata.pixelHeight,
      byteCount: data.count,
      contentType: metadata.contentType
    )
  }

  func saveImages(_ imageData: [Data]) throws -> [CollectionImageAttachment] {
    var savedAttachments: [CollectionImageAttachment] = []

    do {
      for data in imageData {
        savedAttachments.append(try saveImage(data))
      }
      return savedAttachments
    } catch {
      savedAttachments.forEach(delete)
      throw error
    }
  }

  func attachment(
    imageFileName: String?,
    thumbnailFileName: String?,
    pixelWidth: Int?,
    pixelHeight: Int?,
    byteCount: Int?,
    contentType: String?
  ) -> CollectionImageAttachment? {
    guard let imageFileName else {
      return nil
    }

    let imageURL = appSupportDirectory.appending(path: imageFileName)
    let thumbnailURL = thumbnailFileName.map { cachesDirectory.appending(path: $0) }

    return CollectionImageAttachment(
      imageFileName: imageFileName,
      thumbnailFileName: thumbnailFileName,
      imageURL: imageURL,
      thumbnailURL: thumbnailURL,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
      byteCount: byteCount ?? 0,
      contentType: contentType
    )
  }

  func attachment(for record: CollectionImageAttachmentRecord) -> CollectionImageAttachment {
    let imageURL = appSupportDirectory.appending(path: record.imageFileName)
    let thumbnailURL = record.thumbnailFileName.map { cachesDirectory.appending(path: $0) }

    return CollectionImageAttachment(
      imageFileName: record.imageFileName,
      thumbnailFileName: record.thumbnailFileName,
      imageURL: imageURL,
      thumbnailURL: thumbnailURL,
      pixelWidth: record.pixelWidth,
      pixelHeight: record.pixelHeight,
      byteCount: record.byteCount,
      contentType: record.contentType
    )
  }

  func delete(_ attachment: CollectionImageAttachment) {
    try? fileManager.removeItem(at: attachment.imageURL)
    if let thumbnailURL = attachment.thumbnailURL {
      try? fileManager.removeItem(at: thumbnailURL)
    }
  }

  func delete(_ attachments: [CollectionImageAttachment]) {
    attachments.forEach(delete)
  }

  private func protectFile(at url: URL) throws {
    try fileManager.setAttributes(
      [.protectionKey: FileProtectionType.complete],
      ofItemAtPath: url.path
    )
  }

  private func imageMetadata(for data: Data) -> ImageMetadata {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      return ImageMetadata(fileExtension: "img", pixelWidth: nil, pixelHeight: nil, contentType: nil)
    }

    let contentType = CGImageSourceGetType(source) as String?
    let preferredExtension = contentType
      .flatMap { UTType($0)?.preferredFilenameExtension }
      ?? "img"

    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    let pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Int
    let pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Int

    return ImageMetadata(
      fileExtension: preferredExtension,
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
      contentType: contentType
    )
  }

  private func thumbnailData(from data: Data) -> Data? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      return nil
    }

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: 720
    ]

    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
      return nil
    }

    return UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.82)
  }
}

private struct ImageMetadata {
  let fileExtension: String
  let pixelWidth: Int?
  let pixelHeight: Int?
  let contentType: String?
}
