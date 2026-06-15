enum NookSheet: Identifiable, Equatable {
  case add
  case categories
  case capture(String)

  var id: String {
    switch self {
    case .add:
      "add"
    case .categories:
      "categories"
    case let .capture(message):
      "capture-\(message)"
    }
  }
}
