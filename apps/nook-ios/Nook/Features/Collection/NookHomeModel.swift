import Foundation
import Observation

@MainActor
@Observable
final class NookHomeModel {
  enum ComposerMode: Equatable {
    case idle
    case editing
    case sending
    case recording
  }

  var draft = ""
  var entries: [CollectionEntry]
  var suggestions: [NookSuggestion]
  var mode: ComposerMode = .idle
  var activeSheet: NookSheet?
  var selectedSource: CollectionEntry.Source = .text

  init(
    entries: [CollectionEntry] = [],
    suggestions: [NookSuggestion] = NookSuggestion.defaults
  ) {
    self.entries = entries
    self.suggestions = suggestions
  }

  var canSend: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && mode != .sending
  }

  var shouldShowSuggestions: Bool {
    entries.isEmpty && mode != .recording && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func count(for category: CollectionCategory) -> Int {
    entries(for: category).count
  }

  func entries(for category: CollectionCategory) -> [CollectionEntry] {
    entries.filter { entry in
      Self.entry(entry, matches: category)
    }
  }

  func focusDraft() {
    if mode == .idle {
      mode = .editing
    }
  }

  func blurDraft() {
    if mode == .editing && draft.isEmpty {
      mode = .idle
    }
  }

  func apply(_ suggestion: NookSuggestion) {
    selectedSource = suggestion.source
    draft = suggestion.prompt
    mode = .editing
  }

  func sendDraft() {
    let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else {
      return
    }

    mode = .sending
    let title = Self.title(for: content)
    let entry = CollectionEntry(
      title: title,
      detail: content,
      source: selectedSource,
      tags: Self.tags(for: content, source: selectedSource)
    )
    entries.insert(entry, at: 0)
    draft = ""
    selectedSource = .text
    mode = .idle
    rotateSuggestions()
  }

  func add(source: CollectionEntry.Source) {
    selectedSource = source
    switch source {
    case .text:
      draft = ""
      mode = .editing
    case .link:
      draft = "Save this link: "
      mode = .editing
    case .image:
      activeSheet = .capture("Image capture is ready for a photo picker.")
    case .voice:
      toggleRecording()
    case .file:
      activeSheet = .capture("File capture is ready for document import.")
    }
  }

  func toggleRecording() {
    if mode == .recording {
      mode = .editing
      draft = "Voice note transcript: "
    } else {
      selectedSource = .voice
      mode = .recording
    }
  }

  func openCollectionCategories() {
    activeSheet = .categories
  }

  func openAddMenu() {
    activeSheet = .add
  }

  private func rotateSuggestions() {
    guard let first = suggestions.first else {
      return
    }
    suggestions.removeFirst()
    suggestions.append(first)
  }

  private static func title(for content: String) -> String {
    let cleaned = content.replacingOccurrences(of: "\n", with: " ")
    if cleaned.count <= 34 {
      return cleaned
    }
    return String(cleaned.prefix(31)) + "..."
  }

  private static func tags(for content: String, source: CollectionEntry.Source) -> [String] {
    var tags = [source.label.lowercased()]
    if content.localizedCaseInsensitiveContains("idea") {
      tags.append("idea")
    }
    if content.localizedCaseInsensitiveContains("link") || content.contains("http") {
      tags.append("link")
    }
    return Array(Set(tags)).sorted()
  }

  private static func entry(_ entry: CollectionEntry, matches category: CollectionCategory) -> Bool {
    let searchableText = ([entry.title, entry.detail] + entry.tags)
      .joined(separator: " ")
      .lowercased()

    switch category {
    case .pin:
      return containsAny(["pin", "pinned", "save", "saved"], in: searchableText)
    case .todo:
      return containsAny(["todo", "to-do", "task", "checklist", "check list", "- [ ]"], in: searchableText)
    case .highlight:
      return containsAny(["highlight", "highlights", "important", "key point", "keypoint"], in: searchableText)
    case .quotes:
      return containsAny(["quote", "quotes"], in: searchableText)
        || searchableText.contains("\"")
        || searchableText.contains("“")
        || searchableText.contains("”")
    case .photos:
      return entry.source == .image
    case .audio:
      return entry.source == .voice
    case .links:
      return entry.source == .link
        || containsAny(["link", "http://", "https://", "www."], in: searchableText)
    case .remind:
      return containsAny(["remind", "reminder", "tomorrow", "later", "due", "follow up", "follow-up"], in: searchableText)
    }
  }

  private static func containsAny(_ needles: [String], in haystack: String) -> Bool {
    needles.contains { haystack.contains($0) }
  }
}

enum CollectionCategory: String, CaseIterable, Identifiable, Hashable {
  case pin
  case todo
  case highlight
  case quotes
  case photos
  case audio
  case links
  case remind

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .pin:
      "Pin"
    case .todo:
      "To-Do"
    case .highlight:
      "Highlight"
    case .quotes:
      "Quotes"
    case .photos:
      "Photos"
    case .audio:
      "Audio"
    case .links:
      "Links"
    case .remind:
      "Remind"
    }
  }

  var symbolName: String {
    switch self {
    case .pin:
      "pin"
    case .todo:
      "checklist"
    case .highlight:
      "highlighter"
    case .quotes:
      "quote.opening"
    case .photos:
      "photo"
    case .audio:
      "waveform"
    case .links:
      "link"
    case .remind:
      "bell"
    }
  }
}

enum NookSheet: Identifiable, Equatable {
  case add
  case categories
  case capture(String)

  var id: String {
    switch self {
    case .add:
      "add"
    case .categories:
      "categories"
    case let .capture(message):
      "capture-\(message)"
    }
  }
}
