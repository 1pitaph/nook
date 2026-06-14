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
    entries.isEmpty && mode != .recording
  }

  func focusDraft() {
    if mode == .idle {
      mode = .editing
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

  func openCollectionStatus() {
    activeSheet = .status
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
}

enum NookSheet: Identifiable, Equatable {
  case add
  case status
  case capture(String)

  var id: String {
    switch self {
    case .add:
      "add"
    case .status:
      "status"
    case let .capture(message):
      "capture-\(message)"
    }
  }
}
