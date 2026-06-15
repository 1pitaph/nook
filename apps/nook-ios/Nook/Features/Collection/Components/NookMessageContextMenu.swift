import SwiftUI

struct NookMessageContextMenu<Content: View>: View {
  let entry: CollectionEntry
  var isEnabled = true
  var actionHandler: (CollectionEntryAction, CollectionEntry) -> Void
  let content: Content

  init(
    entry: CollectionEntry,
    isEnabled: Bool = true,
    actionHandler: @escaping (CollectionEntryAction, CollectionEntry) -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.entry = entry
    self.isEnabled = isEnabled
    self.actionHandler = actionHandler
    self.content = content()
  }

  var body: some View {
    if isEnabled {
      content.contextMenu {
        let actions = CollectionEntryAction.actions(
          for: entry,
          hasImageContent: CollectionEntryImageResolver.hasImageContent(for: entry)
        )

        ForEach(CollectionEntryAction.Placement.allCases(in: actions), id: \.self) { placement in
          if placement != actions.first?.placement {
            Divider()
          }

          ForEach(actions.filter { $0.placement == placement }) { action in
            Button(role: action.isDestructive ? .destructive : nil) {
              actionHandler(action, entry)
            } label: {
              Label(action.title, systemImage: action.symbolName)
            }
          }
        }
      }
    } else {
      content
    }
  }
}

private extension CollectionEntryAction.Placement {
  static func allCases(in actions: [CollectionEntryAction]) -> [CollectionEntryAction.Placement] {
    Array(Set(actions.map(\.placement))).sorted()
  }
}
