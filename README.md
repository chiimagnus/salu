# 🔥  Salu the Fire

[English](README-en.md)

一个跨平台（macOS/Linux/Windows）的回合制卡牌战斗游戏，灵感来自《杀戮尖塔》、《诡秘之主》和《安德的游戏三部曲》。

## 📥 下载安装

### 方式一：原生 App（开发中 🚧）

使用 Xcode 打开 `SaluNative/SaluNative.xcodeproj` 并运行 `SaluCRH`。

支持平台：
- **macOS** 14+（已支持 ✅）
- **visionOS** 2+（配置中 ⏳）

> 要求：Xcode 16+ / macOS 14+

### 方式二：命令行版本（CLI）

> 需要 Swift 6.2+，可从 [swift.org](https://www.swift.org/install/) 下载

```bash
# 克隆仓库
git clone https://github.com/chiimagnus/salu.git
cd salu

# 运行游戏（随机种子）
swift run
```

### 方式三：直接下载

前往 [Releases](https://github.com/chiimagnus/salu/releases) 页面下载最新版本：

| 平台 | 下载文件 |
|------|----------|
| **macOS** | `salu-macos.tar.gz` |
| **Linux** | `salu-linux-x86_64.tar.gz` |
| **Windows** | `salu-windows-x86_64.zip` |

#### macOS / Linux 使用方法

```bash
# 解压（以 macOS 为例）
tar -xzf salu-macos.tar.gz

# 运行
./salu-macos
```

#### Windows 使用方法

1. 解压 `salu-windows-x86_64.zip`
2. 双击 `salu-windows-x86_64.exe` 或在命令提示符中运行

## 🤝 参与贡献

欢迎贡献！贡献前请先阅读[仓库贡献指南](AGENTS.md)。

本项目按架构分为多层，分别遵循各自模块规范：

- `GameCore`：纯逻辑层（规则/状态/战斗/卡牌/敌人/地图/存档快照模型），见 [GameCore 开发规范](Sources/GameCore/AGENTS.md)
- `GameCLI`：CLI/TUI 表现层（终端渲染/输入/房间流程/持久化落盘实现），见 [GameCLI 开发规范](Sources/GameCLI/AGENTS.md)
- `SaluNative/SaluCRH`：原生 App（Multiplatform SwiftUI + SwiftData，支持 macOS/visionOS），见 [SaluCRH 开发规范](SaluNative/SaluCRH/AGENTS.md)
