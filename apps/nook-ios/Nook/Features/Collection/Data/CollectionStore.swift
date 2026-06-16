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

  func update(_ entry: CollectionEntry) throws -> CollectionEntry {
    guard let persistedEntry = try persistedEntry(for: entry.id) else {
      return try save(entry)
    }

    persistedEntry.update(with: entry)
    try modelContext.save()
    return entry
  }

  func delete(id: UUID) throws {
    try delete(ids: [id])
  }

  func delete(ids: Set<UUID>) throws {
    var attachmentsToDelete: [CollectionImageAttachment] = []

    for id in ids {
      guard let persistedEntry = try persistedEntry(for: id) else {
        continue
      }

      attachmentsToDelete.append(contentsOf: attachments(for: persistedEntry))

      modelContext.delete(persistedEntry)
    }

    try modelContext.save()

    attachmentStore.delete(attachmentsToDelete)
  }

  func saveImage(
    data: Data,
    entryFactory: CollectionEntryFactory
  ) throws -> CollectionEntry {
    try saveImages(data: [data], entryFactory: entryFactory)
  }

  func saveImages(
    data imageData: [Data],
    entryFactory: CollectionEntryFactory
  ) throws -> CollectionEntry {
    let attachments = try attachmentStore.saveImages(imageData)
    let entry = entryFactory.imageEntry(attachments: attachments)
    modelContext.insert(PersistedCollectionEntry(entry: entry))

    do {
      try modelContext.save()
      return entry
    } catch {
      attachmentStore.delete(attachments)
      throw error
    }
  }

  private func persistedEntry(for id: UUID) throws -> PersistedCollectionEntry? {
    var descriptor = FetchDescriptor<PersistedCollectionEntry>(
      predicate: #Predicate<PersistedCollectionEntry> { entry in
        entry.id == id
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }

  private func attachments(for entry: PersistedCollectionEntry) -> [CollectionImageAttachment] {
    if let imageAttachmentsData = entry.imageAttachmentsData,
       let records = try? JSONDecoder().decode([CollectionImageAttachmentRecord].self, from: imageAttachmentsData),
       !records.isEmpty {
      return records.map { attachmentStore.attachment(for: $0) }
    }

    return attachmentStore.attachment(
      imageFileName: entry.imageFileName,
      thumbnailFileName: entry.thumbnailFileName,
      pixelWidth: entry.imagePixelWidth,
      pixelHeight: entry.imagePixelHeight,
      byteCount: entry.imageByteCount,
      contentType: entry.imageContentType
    ).map { [$0] } ?? []
  }
}
