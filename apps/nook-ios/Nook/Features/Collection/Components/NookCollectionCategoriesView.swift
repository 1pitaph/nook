import SwiftUI

struct NookCollectionCategoriesView: View {
  var model: NookHomeModel
  @Environment(\.dismiss) private var dismiss
  @State private var path: [NookCollectionRoute] = []
  @State private var presentedModal: NookCollectionModal?

  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          NookCategoryHeader(totalCount: model.entries.count)

          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CollectionCategory.allCases) { category in
              NavigationLink(value: NookCollectionRoute.category(category)) {
                NookCategoryTile(
                  category: category,
                  count: model.count(for: category)
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(24)
        .padding(.top, 4)
        .padding(.bottom, 28)
      }
      .scrollIndicators(.hidden)
      .safeAreaInset(edge: .bottom) {
        NookCollectionSheetActions(
          close: { dismiss() },
          openSettings: { presentedModal = .settings }
        )
      }
      .navigationDestination(for: NookCollectionRoute.self) { route in
        switch route {
        case let .category(category):
          NookCategoryDetailView(model: model, category: category)
        }
      }
    }
    .sheet(item: $presentedModal) { modal in
      switch modal {
      case .settings:
        NavigationStack {
          NookCollectionSettingsView()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
    }
  }
}

private enum NookCollectionRoute: Hashable {
  case category(CollectionCategory)
}

private enum NookCollectionModal: String, Identifiable {
  case settings

  var id: String {
    rawValue
  }
}

private struct NookCollectionSheetActions: View {
  var close: () -> Void
  var openSettings: () -> Void

  var body: some View {
    HStack {
      NookIconButton(
        systemName: "xmark",
        accessibilityLabel: "Close collection",
        size: 45,
        action: close
      )

      Spacer()

      NookIconButton(
        systemName: "gearshape",
        accessibilityLabel: "Open settings",
        style: .dark,
        size: 45,
        action: openSettings
      )
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 10)
    .background(NookBottomSheetBackground())
  }
}

private struct NookBottomSheetBackground: View {
  var body: some View {
    LinearGradient(
      colors: [
        Color.white.opacity(0.0),
        Color.white.opacity(0.96),
        Color.white
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}

private struct NookCategoryHeader: View {
  var totalCount: Int

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Collection")
          .font(NookFont.app(31, weight: .bold))
          .foregroundStyle(NookTheme.primaryText)

        Text(totalLabel)
          .font(NookFont.app(15, weight: .medium))
          .foregroundStyle(NookTheme.secondaryText)
      }

      Spacer()

      Image(systemName: "square.grid.2x2")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .frame(width: 45, height: 45)
        .background(NookTheme.surface, in: Circle())
    }
    .accessibilityElement(children: .combine)
  }

  private var totalLabel: String {
    if totalCount == 1 {
      return "1 capture sorted by category"
    }
    return "\(totalCount) captures sorted by category"
  }
}

private struct NookCategoryTile: View {
  let category: CollectionCategory
  let count: Int

  var body: some View {
    ZStack(alignment: .topLeading) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: category.symbolName)
          .font(.system(size: 18))
          .foregroundStyle(NookTheme.primaryText)
          .frame(width: 34, height: 34)

        Spacer(minLength: 4)

        Text("\(count)")
          .font(NookFont.app(38))
          .foregroundStyle(NookTheme.primaryText)
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }

      Text(category.label)
        .font(NookFont.app(18))
        .foregroundStyle(NookTheme.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
    .background(NookTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(NookTheme.hairline, lineWidth: 0.5)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(category.label), \(count)")
  }
}

private struct NookCategoryDetailView: View {
  var model: NookHomeModel
  let category: CollectionCategory

  var body: some View {
    let entries = model.entries(for: category)

    ZStack {
      NookMessageTimeline(
        entries: entries,
        topPadding: 12,
        bottomPadding: 28
      )
      .opacity(entries.isEmpty ? 0 : 1)
      .accessibilityHidden(entries.isEmpty)

      if entries.isEmpty {
        ScrollView {
          NookCategoryEmptyState(category: category)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 360)
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
      }
    }
    .navigationTitle(category.label)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct NookCategoryEmptyState: View {
  let category: CollectionCategory

  var body: some View {
    VStack(spacing: 14) {
      Image(systemName: category.symbolName)
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(NookTheme.primaryText)
        .frame(width: 62, height: 62)
        .background(NookTheme.surface, in: Circle())

      Text("No \(category.label) yet")
        .font(NookFont.app(21, weight: .bold))
        .foregroundStyle(NookTheme.primaryText)

      Text("New captures will appear here when they match this category.")
        .font(NookFont.app(16, weight: .medium))
        .foregroundStyle(NookTheme.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 280)
    }
    .accessibilityElement(children: .combine)
  }
}
