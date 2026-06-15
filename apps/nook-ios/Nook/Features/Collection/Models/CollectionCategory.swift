enum CollectionCategory: String, CaseIterable, Identifiable, Hashable {
  case pin
  case todo
  case highlight
  case quotes
  case photos
  case audio
  case links
  case remind

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .pin:
      "Pin"
    case .todo:
      "To-Do"
    case .highlight:
      "Highlight"
    case .quotes:
      "Quotes"
    case .photos:
      "Photos"
    case .audio:
      "Audio"
    case .links:
      "Links"
    case .remind:
      "Remind"
    }
  }

  var symbolName: String {
    switch self {
    case .pin:
      "pin"
    case .todo:
      "checklist"
    case .highlight:
      "highlighter"
    case .quotes:
      "quote.opening"
    case .photos:
      "photo"
    case .audio:
      "waveform"
    case .links:
      "link"
    case .remind:
      "bell"
    }
  }
}
