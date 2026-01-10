# 🔥  Salu the Fire

一个跨平台（macOS/Linux/Windows）的回合制卡牌战斗游戏，灵感来自《杀戮尖塔》、《诡秘之主》和《安德的游戏三部曲》。

## 📥 下载安装

> 注意，下列方式都需要先 Swift 6.2+，可从 [swift.org](https://www.swift.org/install/) 下载

### 方式一：从源码构建（推荐）

```bash
# 克隆仓库
git clone https://github.com/chiimagnus/salu.git
cd salu

# 运行游戏（随机种子）
swift run
```

### 方式二：直接下载

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

欢迎贡献！本项目按架构分为两层：

- `GameCore`：纯逻辑层（规则/状态/战斗/卡牌/敌人/地图/存档快照模型）
- `GameCLI`：CLI/TUI 表现层（终端渲染/输入/房间流程/持久化落盘实现）

贡献前建议先阅读对应规范：

- `GameCore`：`.cursor/rules/GameCore模块开发规范.mdc`
- `GameCLI`：`.cursor/rules/GameCLI模块开发规范.mdc`

### GameCore（纯逻辑层）如何贡献

适用目录：`Sources/GameCore/`

建议你从这些类型入手扩展：

- 新卡牌：新增 `CardDefinition` 并在 `CardRegistry` 注册 `CardID`
- 新状态：新增 `StatusDefinition` 并在 `StatusRegistry` 注册 `StatusID`
- 新敌人：新增 `EnemyDefinition` 并在 `EnemyRegistry` 注册 `EnemyID`
- Run 存档：`GameCore` 只负责 `RunSnapshot/RunSaveVersion` 等快照模型；实际文件读写放在 `GameCLI/Persistence`

测试建议：优先为改动补 `Tests/GameCoreTests/` 单元测试。

### GameCLI（CLI/TUI）如何贡献

适用目录：`Sources/GameCLI/`

常见扩展点：

- 新界面：在 `Sources/GameCLI/Screens/` 增加 screen，并在 `Screens.swift` 挂入口
- 新房间行为：新增 `Rooms/Handlers/*.swift` 并在 `RoomHandlerRegistry` 注册（避免在主循环写 roomType 分支）
- UI 渲染：卡牌/状态/敌人展示尽量从 `CardRegistry/StatusRegistry/EnemyRegistry` 取数据渲染，避免写展示用 `switch`

测试建议：

- 统一跑：`swift test`
- 端到端 CLI “UI” 测试可用：`SALU_TEST_MODE=1 SALU_DATA_DIR=/tmp/salu swift test`

### 提交流程

```bash
git clone https://github.com/chiimagnus/salu.git
cd salu
git checkout -b feat/your-feature
swift test
git add .
git commit -m "feat: your feature description"
git push origin feat/your-feature
```

然后在 GitHub 创建 Pull Request，并在描述里写清楚：做了什么 / 为什么 / 如何验证（附上运行过的命令）。
