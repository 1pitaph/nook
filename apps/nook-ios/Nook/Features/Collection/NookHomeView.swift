import SwiftUI

struct NookHomeView: View {
  @State private var model = NookHomeModel()

  var body: some View {
    @Bindable var model = model

    NookHomeScaffold(model: model)
      .sheet(item: $model.activeSheet) { sheet in
        sheetContent(for: sheet)
      }
      .font(NookFont.app(17))
      .preferredColorScheme(.light)
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
      NookBottomDock(model: model)
    }
  }
}

private struct NookTopBar: View {
  var model: NookHomeModel

  var body: some View {
    HStack {
      Text("nook")
        .font(NookFont.app(31, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)
        .accessibilityAddTraits(.isHeader)

      Spacer()

      NookIconButton(
        systemName: "square.grid.2x2",
        accessibilityLabel: "Open collection categories",
        size: 45
      ) {
        model.openCollectionCategories()
      }
    }
    .frame(height: 58)
  }
}

private struct NookContentCanvas: View {
  var model: NookHomeModel

  var body: some View {
    NookMessageTimeline(
      entries: model.entries,
      topPadding: 24,
      bottomPadding: model.shouldShowSuggestions ? 196 : 116,
      emptyHeight: 420,
      scrollToLatest: true
    )
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
