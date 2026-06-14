# nook iOS

Native SwiftUI prototype for the new nook direction: a chat-shaped collection tool with a quiet canvas, bottom input bar, and lightweight collection actions.

## Requirements

- Xcode 26.5 or newer
- XcodeGen

## Generate Project

```bash
xcodegen generate --spec apps/nook-ios/project.yml
```

## Build

```bash
xcodebuild -project apps/nook-ios/Nook.xcodeproj -scheme Nook -destination 'generic/platform=iOS Simulator' build
```

The source of truth is the Swift files under `apps/nook-ios/Nook` plus `project.yml`; regenerate the Xcode project after changing target structure.
