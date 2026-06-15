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

  private let entryFactory: CollectionEntryFactory
  private let categorizer: CollectionCategorizer

  init(
    entries: [CollectionEntry] = [],
    suggestions: [NookSuggestion] = NookSuggestionCatalog.defaults,
    entryFactory: CollectionEntryFactory = CollectionEntryFactory(),
    categorizer: CollectionCategorizer = CollectionCategorizer()
  ) {
    self.entries = entries
    self.suggestions = suggestions
    self.entryFactory = entryFactory
    self.categorizer = categorizer
  }

  var canSend: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && mode != .sending
  }

  var shouldShowSuggestions: Bool {
    entries.isEmpty && mode != .recording && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func count(for category: CollectionCategory) -> Int {
    categorizer.count(for: category, in: entries)
  }

  func entries(for category: CollectionCategory) -> [CollectionEntry] {
    categorizer.entries(for: category, in: entries)
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
    guard let entry = entryFactory.entry(forDraft: draft) else {
      return
    }

    mode = .sending
    entries.insert(entry, at: 0)
    draft = ""
    selectedSource = .text
    mode = .idle
    rotateSuggestions()
  }

  func addImage(data: Data) {
    mode = .sending
    entries.insert(entryFactory.imageEntry(data: data), at: 0)
    selectedSource = .text
    mode = .idle
    rotateSuggestions()
  }

  func showCaptureMessage(_ message: String) {
    activeSheet = .capture(message)
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
}
