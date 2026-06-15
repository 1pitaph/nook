import Foundation

struct CollectionEntryEditSession: Equatable {
  let originalEntry: CollectionEntry
  let restoredDraft: String
  let restoredSource: CollectionEntry.Source

  var entryID: UUID {
    originalEntry.id
  }
}
