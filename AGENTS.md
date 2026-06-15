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

## Editing Rules

- Keep canonical iOS project configuration in `apps/nook-ios/project.yml`.
- Do not commit `xcuserdata`, `*.xcuserstate`, DerivedData, local `.env` files, or package caches.
- Keep Nook product documentation in Chinese unless a term is a product name, API term, or established acronym.
- Avoid migrating old PawPilot / Pet Mobility documents or app code unless explicitly requested.
