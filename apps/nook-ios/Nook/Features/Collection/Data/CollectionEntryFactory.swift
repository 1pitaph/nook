import Foundation

struct CollectionEntryFactory {
  private let linkDetector: CollectionLinkDetector
  private let titleFormatter: CollectionEntryTitleFormatter
  private let tagger: CollectionEntryTagger

  init(
    linkDetector: CollectionLinkDetector = CollectionLinkDetector(),
    titleFormatter: CollectionEntryTitleFormatter = CollectionEntryTitleFormatter(),
    tagger: CollectionEntryTagger = CollectionEntryTagger()
  ) {
    self.linkDetector = linkDetector
    self.titleFormatter = titleFormatter
    self.tagger = tagger
  }

  func entry(forDraft draft: String) -> CollectionEntry? {
    let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else {
      return nil
    }

    let linkURL = linkDetector.firstLink(in: content)
    let source: CollectionEntry.Source = linkURL == nil ? .text : .link

    return CollectionEntry(
      title: titleFormatter.title(for: content, source: source, linkURL: linkURL),
      detail: content,
      source: source,
      tags: tagger.tags(for: content, source: source, linkURL: linkURL),
      linkURL: linkURL
    )
  }

  func imageEntry(data: Data) -> CollectionEntry {
    imageEntry(data: [data])
  }

  func imageEntry(data imageData: [Data]) -> CollectionEntry {
    let count = imageData.count

    return CollectionEntry(
      title: count == 1 ? "Photo from library" : "Photos from library",
      detail: count == 1 ? "Image selected from Photos." : "\(count) images selected from Photos.",
      source: .image,
      tags: tagger.tags(for: "", source: .image, linkURL: nil),
      imageData: imageData.first,
      imageDatas: imageData
    )
  }

  func imageEntry(attachment: CollectionImageAttachment) -> CollectionEntry {
    imageEntry(attachments: [attachment])
  }

  func imageEntry(attachments: [CollectionImageAttachment]) -> CollectionEntry {
    let count = attachments.count
    let primaryAttachment = attachments.first

    return CollectionEntry(
      title: count == 1 ? "Photo from library" : "Photos from library",
      detail: count == 1 ? "Image selected from Photos." : "\(count) images selected from Photos.",
      source: .image,
      tags: tagger.tags(for: "", source: .image, linkURL: nil),
      imageAttachments: attachments,
      imageFileName: primaryAttachment?.imageFileName,
      thumbnailFileName: primaryAttachment?.thumbnailFileName,
      imageURL: primaryAttachment?.imageURL,
      thumbnailURL: primaryAttachment?.thumbnailURL,
      imagePixelWidth: primaryAttachment?.pixelWidth,
      imagePixelHeight: primaryAttachment?.pixelHeight,
      imageByteCount: primaryAttachment?.byteCount,
      imageContentType: primaryAttachment?.contentType
    )
  }
}

struct CollectionLinkDetector {
  private let detector: NSDataDetector?

  init() {
    detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  }

  func firstLink(in content: String) -> URL? {
    guard let detector else {
      return nil
    }

    let nsContent = content as NSString
    let range = NSRange(location: 0, length: nsContent.length)
    let matches = detector.matches(in: content, options: [], range: range)

    for match in matches {
      guard let url = match.url,
            let normalizedURL = normalizedLink(url) else {
        continue
      }
      return normalizedURL
    }

    return nil
  }

  private func normalizedLink(_ url: URL) -> URL? {
    let trailingPunctuation = CharacterSet(charactersIn: ".,;:!?)]}，。！？、；：）】」』")
    var rawValue = url.absoluteString.trimmingCharacters(in: trailingPunctuation)

    if rawValue.range(of: "www.", options: [.anchored, .caseInsensitive]) != nil {
      rawValue = "https://\(rawValue)"
    }

    guard let normalizedURL = URL(string: rawValue),
          let scheme = normalizedURL.scheme?.lowercased(),
          scheme == "http" || scheme == "https" else {
      return nil
    }

    return normalizedURL
  }
}

struct CollectionEntryTitleFormatter {
  func title(
    for content: String,
    source: CollectionEntry.Source,
    linkURL: URL?
  ) -> String {
    if source == .link, let host = linkURL?.host {
      return host.replacingOccurrences(of: "www.", with: "")
    }

    return title(for: content)
  }

  private func title(for content: String) -> String {
    let cleaned = content.replacingOccurrences(of: "\n", with: " ")
    if cleaned.count <= 34 {
      return cleaned
    }
    return String(cleaned.prefix(31)) + "..."
  }
}

struct CollectionEntryTagger {
  func tags(
    for content: String,
    source: CollectionEntry.Source,
    linkURL: URL?
  ) -> [String] {
    var tags = [source.label.lowercased()]
    if content.localizedCaseInsensitiveContains("idea") {
      tags.append("idea")
    }
    if source == .link && linkURL != nil {
      tags.append("link")
    }
    if source == .image {
      tags.append("photo")
    }
    return Array(Set(tags)).sorted()
  }
}
