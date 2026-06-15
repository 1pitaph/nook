# Repository Guidelines

## Project Structure

This repository is the Nook monorepo.

- `apps/nook-ios/` contains the native SwiftUI iOS prototype.
- `apps/nook-ios/project.yml` is the XcodeGen source of truth.
- `apps/nook-ios/Nook.xcodeproj` is generated from `project.yml`; regenerate it after target, source, or resource changes.
- `packages/` is reserved for shared packages.
- `services/` is reserved for backend services.
- `docs/assets/` stores static documentation and README assets.

## Build And Verification

Use XcodeGen before Xcode project-level verification:

```bash
pnpm ios:generate
```

Build the iOS app for simulator:

```bash
pnpm ios:build
```

Equivalent direct command:

```bash
xcodebuild -project apps/nook-ios/Nook.xcodeproj \
  -scheme Nook \
  -destination 'generic/platform=iOS Simulator' \
  build
```

After each round of code changes, restart the app in the iOS Simulator before reporting back.

## Editing Rules

- Keep canonical iOS project configuration in `apps/nook-ios/project.yml`.
- Do not commit `xcuserdata`, `*.xcuserstate`, DerivedData, local `.env` files, or package caches.
- Keep Nook product documentation in Chinese unless a term is a product name, API term, or established acronym.
- Avoid migrating old PawPilot / Pet Mobility documents or app code unless explicitly requested.

## iOS UI Rules

- Prefer iOS 26 system-native SwiftUI components and Liquid Glass APIs for all new or edited UI components when they fit the design.
- Gate iOS 26-only APIs with `#available(iOS 26.0, *)` and keep an automatic fallback that preserves the older design on earlier iOS versions.
- Prefer shared adaptive styling helpers over duplicating custom backgrounds, borders, and shadows in individual components.

## SwiftUI File Organization

- Keep app-wide reusable UI in `apps/nook-ios/Nook/Components/`; do not move feature-local views there only to shorten a file.
- Organize each feature as `Features/<Feature>/` with optional `Components/`, `Models/`, `Data/`, and `PreviewSupport/` subfolders.
- Use feature `Components/` for reusable, independently previewable, or screen-section SwiftUI subviews within that feature.
- Use feature `Models/` for feature-owned routes, sheet state, view state, and value types. Promote models to `Nook/Models/` only after multiple features or services use them.
- Use feature `Data/` for repositories, stores, import adapters, persistence, networking, and business rules. Keep SwiftUI views out of `Data/`.
- Use feature `PreviewSupport/` for preview hosts, sample data, and generated preview assets. Guard preview-only helpers with `#if DEBUG`.
- Default to SwiftUI MV: keep local state in views, inject shared dependencies through environment, and put business logic in models or services. Introduce view models only when a feature clearly needs a long-lived presentation object.
- Split SwiftUI files once they approach roughly 300 lines or contain multiple logical screens; prefer dedicated `View` types over large computed `some View` fragments.

## XcodeGen Rules

- Treat `apps/nook-ios/project.yml` as canonical; do not hand-edit generated project settings in `Nook.xcodeproj`.
- Run `pnpm ios:generate` after adding, removing, moving, or renaming Swift files or resources, and after target, Info.plist, capability, package, scheme, or build-setting changes.
- Commit `project.yml` and generated `Nook.xcodeproj` changes together when project generation changes the project file.
- Do not edit generated Info.plist values directly unless the matching source-of-truth entry in `project.yml` is also updated.
