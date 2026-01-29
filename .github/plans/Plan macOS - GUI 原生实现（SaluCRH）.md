---
title: Plan macOS - GUI 原生实现（SaluCRH）
date: 2026-01-29
updated: 2026-01-29
architecture: macOS App (SwiftUI)
target: SaluCRH
status: optional
---

# Plan macOS：GUI 原生实现（SaluCRH）

## 0. 定位

macOS 版本当前为 **可选/不阻塞**：后续开发资源将优先投向 `SaluAVP`（Apple Vision Pro 原生 3D）。

如果需要保留 macOS 版本，建议目标仅为：

- 提供一个窗口化 2D GUI（SwiftUI），用于快速调试/验收基础流程
- 逻辑与内容 **100% 复用 `GameCore`**，不依赖 `GameCLI`

## 1. 验证命令参考

```bash
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluCRH \
  -destination 'platform=macOS' \
  build
```

## 2. 建议范围（最小化维护成本）

- 只维护主菜单/地图/战斗的最小闭环（2D）
- 不追求与 AVP 的 3D 表现一致，只保证核心规则一致（由 `GameCore` 保证）
- 尽量避免引入额外的 macOS-only 复杂特性（快捷键体系、复杂窗口管理等）

