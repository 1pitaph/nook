import SwiftUI
import SwiftData

@main
struct NookApp: App {
  init() {
    prepareStorageDirectories()
  }

  var body: some Scene {
    WindowGroup {
      NookHomeView()
    }
    .modelContainer(for: PersistedCollectionEntry.self)
  }

  private func prepareStorageDirectories() {
    let directories = [
      URL.applicationSupportDirectory,
      URL.applicationSupportDirectory.appending(path: "Nook", directoryHint: .isDirectory),
      URL.cachesDirectory.appending(path: "Nook", directoryHint: .isDirectory)
    ]

    for directory in directories {
      try? FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
    }
  }
}
