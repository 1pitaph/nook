import Foundation

struct CollectionDeletionRequest: Identifiable, Equatable {
  enum Scope: Equatable {
    case single(CollectionEntry)
    case selected(Set<UUID>)
  }

  let id = UUID()
  let scope: Scope

  var title: String {
    switch scope {
    case .single:
      "Delete Capture?"
    case let .selected(entryIDs):
      entryIDs.count == 1 ? "Delete Capture?" : "Delete \(entryIDs.count) Captures?"
    }
  }

  var message: String {
    switch scope {
    case .single:
      "This capture will be removed from nook."
    case let .selected(entryIDs):
      entryIDs.count == 1
        ? "This capture will be removed from nook."
        : "These captures will be removed from nook."
    }
  }
}
