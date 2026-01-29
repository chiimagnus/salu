# SaluCRH 模块开发规范

SaluCRH 是 Salu 的 **macOS** 原生 App 前端（2D SwiftUI）。Apple Vision Pro（visionOS）的原生 3D 实现由 `SaluAVP` Target 承担，本模块不包含 RealityKit/ImmersiveSpace 主流程。

## 模块职责

- **UI 层**：SwiftUI 视图、动画、用户交互
- **状态管理**：GameSession 状态机、AppRoute 路由
- **持久化**：SwiftData 存档、战斗历史
- **macOS 适配**：窗口布局、键鼠交互、快捷键（可选）

## 依赖关系

```
SaluCRH → GameCore ✅
GameCore → SaluCRH ❌（禁止反向依赖）
GameCLI ↔ SaluCRH ❌（互不依赖）
```

**核心原则**：所有游戏逻辑来自 `GameCore`，本模块只负责 UI 展示和用户交互。

## 平台支持

- **macOS** 14.0+（当前支持 ✅）

> visionOS：请在 `SaluNative/SaluAVP/`（`SaluAVP` scheme）实现原生 3D 体验，不要在本模块引入 RealityKit。

## 目录结构

```
SaluCRH/
├── SaluCRHApp.swift           # @main 入口
├── ContentView.swift          # 根视图（根据 AppRoute 切换）
├── GameSession.swift          # 流程状态机
├── AppRoute.swift             # 路由枚举
├── Views/                     # SwiftUI 视图
│   ├── MainMenuView.swift
│   ├── MapView.swift
│   ├── BattleView.swift
│   ├── ShopView.swift
│   ├── EventView.swift
│   └── ...
├── ViewModels/                # 视图模型（桥接 GameCore）
│   └── BattleSession.swift    # 包装 BattleEngine
├── Persistence/               # SwiftData 模型
│   ├── RunSaveEntity.swift
│   └── BattleRecordEntity.swift
└── Assets.xcassets
```

## 构建失败排查指南

**重要**：编译错误通常是因为 GameCore API 使用不正确。遇到构建失败时：

1. **查看 GameCore 源码**：错误提示的类型（如 `RunState`、`Entity`、`MapNode` 等）都定义在 `Sources/GameCore/` 中
2. **常见 API 差异**：
   - `RunState.newRun(seed:)` - 创建新冒险（不是直接 `init(seed:)`）
   - `Entity.currentHP` / `Entity.maxHP` - 注意大小写
   - `MapNode.roomType` - 不是 `type`
   - `RelicManager.all` - 获取所有遗物 ID（不是 `relics`）
   - “消耗品”已是 **Consumable Cards**：通过 `CardRegistry` 判断 `CardDefinition.type == .consumable`，并作为实例存在于 `RunState.deck`
3. **技术文档**：完整的 GameCore API 参考见 [GameCore 规范](../../Sources/GameCore/AGENTS.md)
## 禁止事项

- ❌ 在 View 中直接操作 `BattleEngine`（必须通过 `BattleSession`）
- ❌ 引入 UI 层随机源（所有随机通过 GameCore seed 派生）
- ❌ 依赖 `GameCLI`（两者互不依赖）
- ❌ 修改 `GameCore` 来适配 UI（GameCore 保持纯逻辑）
- ❌ 使用单例 ViewModel（使用依赖注入）
- ❌ 猜测 API - 遇到不确定的类型/属性，先查看 GameCore 源码

## 参考文档
- [GameCore 规范](../../Sources/GameCore/AGENTS.md)


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

