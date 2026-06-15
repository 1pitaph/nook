import Foundation

struct CollectionCategorizer {
  func count(for category: CollectionCategory, in entries: [CollectionEntry]) -> Int {
    self.entries(for: category, in: entries).count
  }

  func entries(for category: CollectionCategory, in entries: [CollectionEntry]) -> [CollectionEntry] {
    entries.filter { entry in
      self.entry(entry, matches: category)
    }
  }

  private func entry(_ entry: CollectionEntry, matches category: CollectionCategory) -> Bool {
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
        || entry.linkURL != nil
        || containsAny(["http://", "https://", "www."], in: searchableText)
    case .remind:
      return containsAny(["remind", "reminder", "tomorrow", "later", "due", "follow up", "follow-up"], in: searchableText)
    }
  }

  private func containsAny(_ needles: [String], in haystack: String) -> Bool {
    needles.contains { haystack.contains($0) }
  }
}
