import Foundation

struct NookSuggestion: Identifiable, Equatable {
  let id: String
  var title: String
  var subtitle: String
  var prompt: String
  var source: CollectionEntry.Source
}

enum NookSuggestionCatalog {
  static let defaults: [NookSuggestion] = [
    NookSuggestion(
      id: "collect-idea",
      title: "Collect an idea",
      subtitle: "for later shaping",
      prompt: "Collect this idea: ",
      source: .text
    ),
    NookSuggestion(
      id: "save-link",
      title: "Save a link",
      subtitle: "with a quick note",
      prompt: "Save this link and note why it matters: ",
      source: .link
    ),
    NookSuggestion(
      id: "make-list",
      title: "Make a list",
      subtitle: "from scattered notes",
      prompt: "Turn these notes into a clean list: ",
      source: .text
    ),
    NookSuggestion(
      id: "capture-file",
      title: "Capture a file",
      subtitle: "then summarize it",
      prompt: "Capture this file and summarize the key points: ",
      source: .file
    )
  ]
}
