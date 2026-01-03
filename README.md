# 🗡️ Salu - 杀戮尖塔 CLI 版

一个跨平台（macOS/Linux/Windows）的纯 CLI 回合制卡牌战斗游戏，灵感来自《杀戮尖塔》（Slay the Spire）。

## 🚀 快速开始

### 运行游戏

```bash
# 克隆仓库
git clone https://github.com/chiimagnus/salu.git
cd salu

# 运行游戏（随机种子）
swift run
```

## 🤝 参与贡献

欢迎贡献代码！请遵循以下工作流：

### 1. Fork 仓库

点击右上角的 **Fork** 按钮。

### 2. 克隆你的 Fork 仓库

```bash
git clone https://github.com/<你的用户名>/salu.git
cd salu
git checkout -b feature/你的功能名
```

### 3. 开发与测试

```bash
# 本地测试（必须全部通过）
./.cursor/Scripts/test_game.sh all
```

### 4. 提交代码

```bash
git add .
git commit -m "✨ 添加xxx功能"
git push origin feature/你的功能名
```

### 5. 创建 Pull Request

在 GitHub 上创建 PR，填写清晰的标题和描述。

## 📋 路线图
详细规划请查看 [architecture-design.md](.cursor/plans/architecture-design.md)。
