import Foundation

enum CollectionEntryAction: String, CaseIterable, Identifiable {
  case copy
  case edit
  case share
  case openLink
  case copyLink
  case shareLink
  case copyImage
  case saveImage
  case shareImage
  case select
  case delete

  enum Placement: Int, Comparable {
    case primary
    case selection
    case destructive

    static func < (lhs: Placement, rhs: Placement) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .copy:
      "Copy"
    case .edit:
      "Edit"
    case .share:
      "Share"
    case .openLink:
      "Open Link"
    case .copyLink:
      "Copy Link"
    case .shareLink:
      "Share Link"
    case .copyImage:
      "Copy Image"
    case .saveImage:
      "Save Image"
    case .shareImage:
      "Share Image"
    case .select:
      "Select"
    case .delete:
      "Delete"
    }
  }

  var symbolName: String {
    switch self {
    case .copy:
      "doc.on.doc"
    case .edit:
      "pencil"
    case .share:
      "square.and.arrow.up"
    case .openLink:
      "safari"
    case .copyLink:
      "link"
    case .shareLink:
      "square.and.arrow.up"
    case .copyImage:
      "photo.on.rectangle"
    case .saveImage:
      "square.and.arrow.down"
    case .shareImage:
      "square.and.arrow.up"
    case .select:
      "checkmark.circle"
    case .delete:
      "trash"
    }
  }

  var placement: Placement {
    switch self {
    case .select:
      .selection
    case .delete:
      .destructive
    case .copy, .edit, .share, .openLink, .copyLink, .shareLink, .copyImage, .saveImage, .shareImage:
      .primary
    }
  }

  var isDestructive: Bool {
    self == .delete
  }

  static func actions(
    for entry: CollectionEntry,
    hasImageContent: Bool
  ) -> [CollectionEntryAction] {
    switch entry.source {
    case .text:
      [.copy, .edit, .share, .select, .delete]
    case .link:
      [.copy, .edit, .openLink, .copyLink, .shareLink, .select, .delete]
    case .image:
      hasImageContent
        ? [.copyImage, .saveImage, .shareImage, .select, .delete]
        : [.select, .delete]
    case .voice, .file:
      [.copy, .share, .select, .delete]
    }
  }
}
