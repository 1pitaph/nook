import PhotosUI
import SwiftUI

struct NookAddMenu: View {
  var model: NookHomeModel
  @Environment(\.dismiss) private var dismiss
  @State private var selectedPhotoItems: [PhotosPickerItem] = []

  private let maxPhotoSelectionCount = 12
  private let sources: [CollectionEntry.Source] = [.text, .link, .image, .voice, .file]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add to nook")
        .font(NookFont.app(25, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
        ForEach(sources, id: \.self) { source in
          if source == .image {
            PhotosPicker(
              selection: $selectedPhotoItems,
              maxSelectionCount: maxPhotoSelectionCount,
              selectionBehavior: .ordered,
              matching: .images
            ) {
              NookAddSourceTile(source: source)
            }
            .buttonStyle(.plain)
          } else {
            Button {
              add(source)
            } label: {
              NookAddSourceTile(source: source)
            }
            .buttonStyle(.plain)
          }
        }
      }

      Spacer(minLength: 0)
    }
    .padding(24)
    .onChange(of: selectedPhotoItems) { _, newItems in
      handlePhotoSelection(newItems)
    }
  }

  private func add(_ source: CollectionEntry.Source) {
    dismiss()
    model.add(source: source)
  }

  private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
    guard !items.isEmpty else {
      return
    }

    dismiss()
    loadPhotos(items)
  }

  private func loadPhotos(_ items: [PhotosPickerItem]) {
    Task {
      var imageData: [Data] = []

      for item in items {
        do {
          if let data = try await item.loadTransferable(type: Data.self) {
            imageData.append(data)
          }
        } catch {
          continue
        }
      }

      if imageData.isEmpty {
        model.showCaptureMessage("Nook could not read that image.")
      } else {
        model.addImages(data: imageData)
      }

      await MainActor.run {
        selectedPhotoItems = []
      }
    }
  }
}

private struct NookAddSourceTile: View {
  let source: CollectionEntry.Source

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: source.symbolName)
        .font(.system(size: 22, weight: .semibold))
        .frame(width: 44, height: 44)
        .background(Color.black.opacity(0.055), in: Circle())

      Text(source.label)
        .font(NookFont.app(14, weight: .semibold))
    }
    .foregroundStyle(NookTheme.primaryText)
    .frame(maxWidth: .infinity)
    .frame(height: 106)
    .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}
