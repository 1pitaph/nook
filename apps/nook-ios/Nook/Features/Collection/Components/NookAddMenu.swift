import PhotosUI
import SwiftUI

struct NookAddMenu: View {
  var model: NookHomeModel
  @Environment(\.dismiss) private var dismiss
  @State private var selectedPhotoItem: PhotosPickerItem?

  private let sources: [CollectionEntry.Source] = [.text, .link, .image, .voice, .file]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Add to nook")
        .font(NookFont.app(25, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
        ForEach(sources, id: \.self) { source in
          if source == .image {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
    .onChange(of: selectedPhotoItem) { _, newItem in
      handlePhotoSelection(newItem)
    }
  }

  private func add(_ source: CollectionEntry.Source) {
    dismiss()
    model.add(source: source)
  }

  private func handlePhotoSelection(_ item: PhotosPickerItem?) {
    guard let item else {
      return
    }

    dismiss()
    loadPhoto(item)
  }

  private func loadPhoto(_ item: PhotosPickerItem) {
    Task {
      do {
        if let data = try await item.loadTransferable(type: Data.self) {
          model.addImage(data: data)
        } else {
          model.showCaptureMessage("Nook could not read that image.")
        }
      } catch {
        model.showCaptureMessage("Nook could not read that image.")
      }

      await MainActor.run {
        selectedPhotoItem = nil
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
