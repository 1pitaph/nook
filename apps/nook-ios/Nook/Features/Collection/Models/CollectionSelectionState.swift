import Foundation

struct CollectionSelectionState: Equatable {
  private(set) var isSelecting = false
  private(set) var selectedEntryIDs: Set<UUID> = []

  var selectedCount: Int {
    selectedEntryIDs.count
  }

  func contains(_ entry: CollectionEntry) -> Bool {
    selectedEntryIDs.contains(entry.id)
  }

  mutating func enter(with entry: CollectionEntry) {
    isSelecting = true
    selectedEntryIDs = [entry.id]
  }

  mutating func toggle(_ entry: CollectionEntry) {
    guard isSelecting else {
      enter(with: entry)
      return
    }

    if selectedEntryIDs.contains(entry.id) {
      selectedEntryIDs.remove(entry.id)
    } else {
      selectedEntryIDs.insert(entry.id)
    }
  }

  mutating func clear() {
    isSelecting = false
    selectedEntryIDs.removeAll()
  }

  mutating func remove(_ entryIDs: Set<UUID>) {
    selectedEntryIDs.subtract(entryIDs)
    if selectedEntryIDs.isEmpty {
      clear()
    }
  }
}
