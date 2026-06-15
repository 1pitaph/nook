import Foundation
import Photos
import UIKit

extension NookHomeModel {
  var hasDraftContent: Bool {
    !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func perform(_ action: CollectionEntryAction, on entry: CollectionEntry) {
    switch action {
    case .copy:
      copyText(entry.detail)
    case .edit:
      startEditing(entry: entry)
    case .share:
      shareText(entry)
    case .openLink:
      openLink(for: entry)
    case .copyLink:
      copyLink(for: entry)
    case .shareLink:
      shareLink(entry)
    case .copyImage:
      copyImage(entry)
    case .saveImage:
      saveImage(entry)
    case .shareImage:
      shareImage(entry)
    case .select:
      enterSelection(with: entry)
    case .delete:
      requestDeletion(of: entry)
    }
  }

  func startEditing(entry: CollectionEntry) {
    guard entry.source == .text || entry.source == .link else {
      return
    }

    clearSelection()
    editingSession = CollectionEntryEditSession(
      originalEntry: entry,
      restoredDraft: draft,
      restoredSource: selectedSource
    )
    draft = entry.detail
    selectedSource = entry.source
    mode = .editing
  }

  func saveEditingDraft() {
    guard let editingSession else {
      return
    }

    let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !content.isEmpty else {
      return
    }

    guard content != editingSession.originalEntry.detail else {
      finishEditing()
      return
    }

    guard let replacement = entryFactory.entry(forDraft: content) else {
      return
    }

    let updatedEntry = CollectionEntry(
      id: editingSession.originalEntry.id,
      title: replacement.title,
      detail: replacement.detail,
      source: replacement.source,
      createdAt: editingSession.originalEntry.createdAt,
      tags: replacement.tags,
      linkURL: replacement.linkURL
    )

    mode = .sending
    do {
      let savedEntry = try collectionStore?.update(updatedEntry) ?? updatedEntry
      replaceEntry(savedEntry)
      finishEditing()
    } catch {
      mode = .editing
      activeSheet = .capture("Nook could not save those changes.")
    }
  }

  func cancelEditing() {
    finishEditing()
  }

  func enterSelection(with entry: CollectionEntry) {
    if editingSession != nil {
      cancelEditing()
    }
    selectionState.enter(with: entry)
  }

  func toggleSelection(for entry: CollectionEntry) {
    selectionState.toggle(entry)
  }

  func clearSelection() {
    selectionState.clear()
  }

  func copySelectedEntries() {
    let selectedText = entries
      .filter { selectionState.selectedEntryIDs.contains($0.id) }
      .map(\.detail)
      .joined(separator: "\n\n")

    guard !selectedText.isEmpty else {
      return
    }

    copyText(selectedText)
  }

  func requestDeletion(of entry: CollectionEntry) {
    pendingDeletion = CollectionDeletionRequest(scope: .single(entry))
  }

  func requestSelectedDeletion() {
    guard hasSelectedEntries else {
      return
    }

    pendingDeletion = CollectionDeletionRequest(
      scope: .selected(selectionState.selectedEntryIDs)
    )
  }

  func confirmPendingDeletion() {
    guard let pendingDeletion else {
      return
    }

    switch pendingDeletion.scope {
    case let .single(entry):
      delete(entry: entry)
    case .selected:
      deleteSelectedEntries()
    }

    self.pendingDeletion = nil
  }

  func delete(entry: CollectionEntry) {
    do {
      try collectionStore?.delete(id: entry.id)
      entries.removeAll { $0.id == entry.id }
      selectionState.remove([entry.id])

      if editingSession?.entryID == entry.id {
        cancelEditing()
      }
    } catch {
      activeSheet = .capture("Nook could not delete that item.")
    }
  }

  func deleteSelectedEntries() {
    let selectedEntryIDs = selectionState.selectedEntryIDs
    guard !selectedEntryIDs.isEmpty else {
      return
    }

    do {
      try collectionStore?.delete(ids: selectedEntryIDs)
      entries.removeAll { selectedEntryIDs.contains($0.id) }
      clearSelection()

      if let editingEntryID = editingSession?.entryID,
         selectedEntryIDs.contains(editingEntryID) {
        cancelEditing()
      }
    } catch {
      activeSheet = .capture("Nook could not delete those items.")
    }
  }

  private func finishEditing() {
    guard let editingSession else {
      return
    }

    draft = editingSession.restoredDraft
    selectedSource = editingSession.restoredSource
    self.editingSession = nil
    mode = hasDraftContent ? .editing : .idle
  }

  private func replaceEntry(_ entry: CollectionEntry) {
    guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
      entries.insert(entry, at: 0)
      return
    }

    entries[index] = entry
  }

  private func copyText(_ text: String) {
    UIPasteboard.general.string = text
  }

  private func shareText(_ entry: CollectionEntry) {
    activeShareItem = CollectionShareItem(
      title: entry.title,
      items: [entry.detail]
    )
  }

  private func openLink(for entry: CollectionEntry) {
    guard let linkURL = entry.linkURL else {
      return
    }

    UIApplication.shared.open(linkURL)
  }

  private func copyLink(for entry: CollectionEntry) {
    guard let linkURL = entry.linkURL else {
      return
    }

    copyText(linkURL.absoluteString)
  }

  private func shareLink(_ entry: CollectionEntry) {
    guard let linkURL = entry.linkURL else {
      shareText(entry)
      return
    }

    activeShareItem = CollectionShareItem(
      title: entry.title,
      items: [linkURL]
    )
  }

  private func copyImage(_ entry: CollectionEntry) {
    guard let image = CollectionEntryImageResolver.image(for: entry) else {
      return
    }

    UIPasteboard.general.image = image
  }

  private func shareImage(_ entry: CollectionEntry) {
    guard let image = CollectionEntryImageResolver.image(for: entry) else {
      return
    }

    activeShareItem = CollectionShareItem(
      title: entry.title,
      items: [image]
    )
  }

  private func saveImage(_ entry: CollectionEntry) {
    guard let image = CollectionEntryImageResolver.image(for: entry) else {
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
      guard status == .authorized || status == .limited else {
        Task { @MainActor in
          self?.activeSheet = .capture("Nook could not access Photos.")
        }
        return
      }

      PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      } completionHandler: { success, _ in
        Task { @MainActor in
          self?.activeSheet = .capture(
            success ? "Image saved to Photos." : "Nook could not save that image."
          )
        }
      }
    }
  }
}
