# nook iOS

`nook` 是 Nook 的原生 SwiftUI 原型：一个聊天式收集工具，使用安静的空白画布、底部输入栏和轻量收集动作，帮助用户先保存想法、链接、图片、语音和文件，再逐步整理。

## 当前范围

这是 `Prototype / 0.1.0` 阶段的交互原型。

- 已实现：底部输入栏、快捷建议、收集条目卡片、添加来源菜单、收集状态面板、SwiftUI Preview。
- 已占位：图片选择器、文件导入、语音录制与转写。
- 尚未实现：本地持久化、账号体系、同步、真实 AI 摘要与归档。

## 环境要求

- Xcode 26.5 或更新版本
- XcodeGen

## 生成工程

```bash
xcodegen generate --spec apps/nook-ios/project.yml
```

## 打开工程

```bash
open apps/nook-ios/Nook.xcodeproj
```

## 构建

```bash
xcodebuild -project apps/nook-ios/Nook.xcodeproj \
  -scheme Nook \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## SwiftUI Preview

打开 `apps/nook-ios/Nook/Features/Collection/NookHomeView.swift`，可以查看两个 Preview：

- `Empty`：空画布、底部输入栏和快捷建议。
- `With captures`：已有收集条目的界面状态。

## 源码结构

```text
Nook/App/                    App 入口
Nook/Components/             复用按钮组件
Nook/Design/                 NookTheme 与基础视觉样式
Nook/Features/Collection/    首页、输入栏、收集状态和交互模型
Nook/Models/                 CollectionEntry 与 NookSuggestion
Nook/Resources/              App icon、accent color 等资源
project.yml                  XcodeGen 项目配置
```

Swift 文件和 `project.yml` 是当前事实来源。修改 target、目录结构或资源配置后，请重新运行 XcodeGen 生成工程。
