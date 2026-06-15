import Foundation

struct CollectionShareItem: Identifiable {
  let id = UUID()
  let title: String
  let items: [Any]
}
