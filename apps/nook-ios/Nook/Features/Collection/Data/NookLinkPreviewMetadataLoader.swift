import Combine
import Foundation
@preconcurrency import LinkPresentation
import UIKit

@MainActor
final class NookLinkPreviewLoader: ObservableObject {
  @Published private(set) var preview = NookResolvedLinkPreview()

  private static var cache: [URL: NookResolvedLinkPreview] = [:]
  private var loadedURL: URL?

  func load(for url: URL?) async {
    guard let url else {
      loadedURL = nil
      preview = NookResolvedLinkPreview()
      return
    }

    if loadedURL == url, preview.hasLoaded {
      return
    }

    if let cachedPreview = Self.cache[url] {
      loadedURL = url
      preview = cachedPreview
      return
    }

    loadedURL = url
    preview = NookResolvedLinkPreview(isLoading: true)

    var resolvedPreview = NookResolvedLinkPreview(hasLoaded: true)

    if let metadata = try? await Self.metadata(for: url) {
      resolvedPreview.title = metadata.title
      resolvedPreview.image = await Self.image(from: metadata.imageProvider)
      resolvedPreview.icon = await Self.image(from: metadata.iconProvider)
    }

    if let webMetadata = try? await Self.webMetadata(for: url) {
      resolvedPreview.siteName = webMetadata.siteName
      resolvedPreview.summary = webMetadata.summary
    }

    guard !Task.isCancelled, loadedURL == url else {
      return
    }

    Self.cache[url] = resolvedPreview
    preview = resolvedPreview
  }

  private static func metadata(for url: URL) async throws -> LPLinkMetadata {
    let provider = LPMetadataProvider()
    return try await provider.startFetchingMetadata(for: url)
  }

  private static func image(from itemProvider: NSItemProvider?) async -> UIImage? {
    guard let itemProvider,
          itemProvider.canLoadObject(ofClass: UIImage.self) else {
      return nil
    }

    return await withCheckedContinuation { continuation in
      itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
        continuation.resume(returning: object as? UIImage)
      }
    }
  }

  private static func webMetadata(for url: URL) async throws -> NookWebLinkMetadata {
    var request = URLRequest(
      url: url,
      cachePolicy: .returnCacheDataElseLoad,
      timeoutInterval: 4
    )
    request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
    request.setValue("bytes=0-120000", forHTTPHeaderField: "Range")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 206 else {
      throw URLError(.badServerResponse)
    }

    let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased()
    guard contentType?.contains("text/html") ?? true else {
      throw URLError(.cannotDecodeContentData)
    }

    guard let html = String(data: data, encoding: .utf8)
      ?? String(data: data, encoding: .isoLatin1) else {
      throw URLError(.cannotDecodeContentData)
    }

    return NookHTMLMetadataParser.metadata(from: String(html.prefix(120_000)))
  }
}

struct NookResolvedLinkPreview {
  var title: String?
  var siteName: String?
  var summary: String?
  var image: UIImage?
  var icon: UIImage?
  var hasLoaded = false
  var isLoading = false
}

private struct NookWebLinkMetadata {
  var siteName: String?
  var summary: String?
}

private enum NookHTMLMetadataParser {
  static func metadata(from html: String) -> NookWebLinkMetadata {
    let attributesByTag = metaTags(in: html).map(attributes(in:))
    let siteName = firstContent(
      in: attributesByTag,
      matching: ["og:site_name", "application-name", "twitter:site"]
    )?.replacingOccurrences(of: "@", with: "")
    let summary = firstContent(
      in: attributesByTag,
      matching: ["og:description", "twitter:description", "description"]
    )

    return NookWebLinkMetadata(siteName: siteName, summary: summary)
  }

  private static func metaTags(in html: String) -> [String] {
    guard let regex = try? NSRegularExpression(
      pattern: #"<meta\b[^>]*>"#,
      options: [.caseInsensitive, .dotMatchesLineSeparators]
    ) else {
      return []
    }

    let range = NSRange(html.startIndex..<html.endIndex, in: html)
    return regex.matches(in: html, range: range).compactMap { match in
      Range(match.range, in: html).map { String(html[$0]) }
    }
  }

  private static func attributes(in tag: String) -> [String: String] {
    guard let regex = try? NSRegularExpression(
      pattern: #"([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(["'])(.*?)\2"#,
      options: [.caseInsensitive, .dotMatchesLineSeparators]
    ) else {
      return [:]
    }

    let range = NSRange(tag.startIndex..<tag.endIndex, in: tag)
    return regex.matches(in: tag, range: range).reduce(into: [:]) { attributes, match in
      guard let nameRange = Range(match.range(at: 1), in: tag),
            let valueRange = Range(match.range(at: 3), in: tag) else {
        return
      }

      attributes[String(tag[nameRange]).lowercased()] = clean(String(tag[valueRange]))
    }
  }

  private static func firstContent(
    in attributesByTag: [[String: String]],
    matching keys: Set<String>
  ) -> String? {
    for attributes in attributesByTag {
      guard let key = attributes["property"] ?? attributes["name"],
            keys.contains(key.lowercased()),
            let content = attributes["content"]?.nonEmpty else {
        continue
      }

      return content
    }

    return nil
  }

  private static func clean(_ value: String) -> String {
    decodeEntities(in: value)
      .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func decodeEntities(in value: String) -> String {
    var result = value
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&apos;", with: "'")
      .replacingOccurrences(of: "&nbsp;", with: " ")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")

    guard let regex = try? NSRegularExpression(pattern: #"&#(x?[0-9A-Fa-f]+);"#) else {
      return result
    }

    let range = NSRange(result.startIndex..<result.endIndex, in: result)
    for match in regex.matches(in: result, range: range).reversed() {
      guard let tokenRange = Range(match.range(at: 1), in: result),
            let fullRange = Range(match.range, in: result) else {
        continue
      }

      let token = String(result[tokenRange])
      let value: Int?
      if token.lowercased().hasPrefix("x") {
        value = Int(token.dropFirst(), radix: 16)
      } else {
        value = Int(token)
      }

      guard let value,
            let scalar = UnicodeScalar(value) else {
        continue
      }

      result.replaceSubrange(fullRange, with: String(scalar))
    }

    return result
  }
}

enum NookLinkPreviewFormatting {
  static func siteName(for url: URL) -> String? {
    url.host?
      .replacingOccurrences(of: "www.", with: "")
      .nonEmpty
  }

  static func noteText(in detail: String, excluding url: URL?) -> String? {
    var note = detail
    if let url {
      note = note.replacingOccurrences(of: url.absoluteString, with: "")
      if let host = url.host {
        note = note.replacingOccurrences(of: host, with: "")
      }
    }

    return note
      .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: ":-|,，。 "))
      .nonEmpty
  }
}

extension Optional where Wrapped == String {
  var nonEmpty: String? {
    switch self {
    case let .some(value):
      value.nonEmpty
    case .none:
      nil
    }
  }
}

extension String {
  var nonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
