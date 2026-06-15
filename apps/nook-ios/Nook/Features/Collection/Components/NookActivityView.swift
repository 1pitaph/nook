import SwiftUI
import UIKit

struct NookActivityView: UIViewControllerRepresentable {
  let item: CollectionShareItem

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: item.items,
      applicationActivities: nil
    )
    controller.title = item.title
    return controller
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {}
}
