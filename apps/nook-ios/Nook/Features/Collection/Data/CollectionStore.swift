import Foundation
import SwiftData

@MainActor
struct CollectionStore {
  private let modelContext: ModelContext
  private let attachmentStore: CollectionAttachmentStore

  init(
    modelContext: ModelContext,
    attachmentStore: CollectionAttachmentStore = CollectionAttachmentStore()
  ) {
    self.modelContext = modelContext
    self.attachmentStore = attachmentStore
  }

  func loadEntries() throws -> [CollectionEntry] {
    let descriptor = FetchDescriptor<PersistedCollectionEntry>(
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).map { persistedEntry in
      persistedEntry.entry(attachmentStore: attachmentStore)
    }
  }

  func save(_ entry: CollectionEntry) throws -> CollectionEntry {
    modelContext.insert(PersistedCollectionEntry(entry: entry))
    try modelContext.save()
    return entry
  }

  func saveImage(
    data: Data,
    entryFactory: CollectionEntryFactory
  ) throws -> CollectionEntry {
    let attachment = try attachmentStore.saveImage(data)
    let entry = entryFactory.imageEntry(attachment: attachment)
    modelContext.insert(PersistedCollectionEntry(entry: entry))

    do {
      try modelContext.save()
      return entry
    } catch {
      attachmentStore.delete(attachment)
      throw error
    }
  }
}
