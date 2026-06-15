import SwiftUI
import SwiftData

struct NookHomeView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var model: NookHomeModel?

  var body: some View {
    Group {
      if let model {
        NookHomeContent(model: model)
      } else {
        NookHomeLoadingView()
      }
    }
    .task {
      configureModelIfNeeded()
    }
  }

  private func configureModelIfNeeded() {
    guard model == nil else {
      return
    }

    let collectionStore = CollectionStore(modelContext: modelContext)
    let loadedModel = NookHomeModel(collectionStore: collectionStore)
    loadedModel.loadPersistedEntries()
    model = loadedModel
  }
}

private struct NookHomeContent: View {
  @Bindable var model: NookHomeModel

  var body: some View {
    NookHomeScaffold(model: model)
      .sheet(item: $model.activeSheet) { sheet in
        sheetContent(for: sheet)
      }
      .sheet(item: $model.activeShareItem) { shareItem in
        NookActivityView(item: shareItem)
      }
      .confirmationDialog(
        model.pendingDeletion?.title ?? "Delete Capture?",
        isPresented: deletionDialogBinding,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          model.confirmPendingDeletion()
        }

        Button("Cancel", role: .cancel) {
          model.pendingDeletion = nil
        }
      } message: {
        Text(model.pendingDeletion?.message ?? "This capture will be removed from nook.")
      }
      .font(NookFont.app(17))
      .preferredColorScheme(.light)
  }

  private var deletionDialogBinding: Binding<Bool> {
    Binding {
      model.pendingDeletion != nil
    } set: { isPresented in
      if !isPresented {
        model.pendingDeletion = nil
      }
    }
  }

  @ViewBuilder
  private func sheetContent(for sheet: NookSheet) -> some View {
    switch sheet {
    case .add:
      NookAddMenu(model: model)
        .presentationDetents([.height(310)])
        .presentationDragIndicator(.visible)
    case .categories:
      NookCollectionCategoriesView(model: model)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    case let .capture(message):
      NookCapturePlaceholder(message: message)
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
    }
  }
}

private struct NookHomeLoadingView: View {
  var body: some View {
    ZStack {
      NookTheme.background
        .ignoresSafeArea()

      ProgressView()
        .tint(NookTheme.primaryText)
    }
    .preferredColorScheme(.light)
  }
}

struct NookHomeScaffold: View {
  var model: NookHomeModel

  var body: some View {
    ZStack {
      NookTheme.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        NookTopBar(model: model)
          .padding(.horizontal, 24)
          .padding(.top, 10)

        NookContentCanvas(model: model)
      }
    }
    .safeAreaInset(edge: .bottom) {
      if model.selectionState.isSelecting {
        NookSelectionToolbar(model: model)
      } else {
        NookBottomDock(model: model)
      }
    }
  }
}

private struct NookTopBar: View {
  var model: NookHomeModel

  var body: some View {
    HStack(spacing: 0) {
      Text("nook")
        .font(NookFont.app(31, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)
        .accessibilityAddTraits(.isHeader)

      Spacer(minLength: 12)

      if let activeCategoryFilter = model.activeCategoryFilter {
        NookActiveFilterPill(
          category: activeCategoryFilter,
          clear: {
            model.clearFilter()
          },
          openCollection: {
            model.openCollectionCategories()
          }
        )
        .transition(.scale(scale: 0.94).combined(with: .opacity))
      } else {
        NookIconButton(
          systemName: "square.grid.2x2",
          accessibilityLabel: "Open collection categories",
          size: 45
        ) {
          model.openCollectionCategories()
        }
      }
    }
    .frame(height: 58)
    .animation(.snappy(duration: 0.24), value: model.activeCategoryFilter)
  }
}

private struct NookContentCanvas: View {
  var model: NookHomeModel

  var body: some View {
    NookMessageTimeline(
      entries: model.visibleEntries,
      topPadding: 24,
      bottomPadding: bottomPadding,
      emptyHeight: 420,
      scrollToLatest: true,
      selectionState: model.selectionState,
      actionHandler: { action, entry in
        model.perform(action, on: entry)
      },
      selectionHandler: { entry in
        model.toggleSelection(for: entry)
      }
    )
  }

  private var bottomPadding: CGFloat {
    if model.selectionState.isSelecting {
      return 96
    }

    return model.shouldShowSuggestions ? 196 : 24
  }
}

private struct NookActiveFilterPill: View {
  let category: CollectionCategory
  var clear: () -> Void
  var openCollection: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: clear) {
        Image(systemName: "xmark")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 22, height: 22)
          .background(NookTheme.primaryText, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Clear \(category.label) filter")

      Button(action: openCollection) {
        Text(category.label)
          .font(NookFont.app(15, weight: .semibold))
          .foregroundStyle(NookTheme.primaryText)
          .lineLimit(1)
          .minimumScaleFactor(0.78)
          .frame(minHeight: 38, alignment: .leading)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open \(category.label) collection")
    }
    .padding(.leading, 8)
    .padding(.trailing, 14)
    .frame(height: 38)
    .fixedSize(horizontal: true, vertical: false)
    .nookAdaptiveSurface(
      in: Capsule(),
      fallbackFill: NookTheme.surface,
      fallbackShadow: NookTheme.tightShadow,
      isInteractive: true
    )
    .accessibilityElement(children: .contain)
  }
}

private struct NookCapturePlaceholder: View {
  var message: String
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 18) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 42, weight: .semibold))
        .foregroundStyle(NookTheme.success)

      Text(message)
        .font(NookFont.app(18, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button("Done", action: dismiss.callAsFunction)
        .font(NookFont.app(17, weight: .semibold))
        .buttonStyle(.borderedProminent)
        .tint(.black)
    }
    .padding(24)
  }
}
