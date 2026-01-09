# 🗡️ Salu - 杀戮尖塔 CLI 版

一个跨平台（macOS/Linux/Windows）的纯 CLI 回合制卡牌战斗游戏，灵感来自《杀戮尖塔》（Slay the Spire）。

## 📥 下载安装

### 方式一：直接下载（推荐）

前往 [Releases](https://github.com/chiimagnus/salu/releases) 页面下载最新版本：

| 平台 | 下载文件 | 说明 |
|------|----------|------|
| **macOS** | `Salu-macos-*.zip` | 📦 双击即可运行的 .app 应用 |
| macOS | `salu-macos.tar.gz` | 命令行二进制，需在终端运行 |
| **Linux** | `salu-linux-x86_64.tar.gz` | Ubuntu 22.04+ 命令行二进制 |
| **Windows** | `salu-windows-x86_64.zip` | Windows 10+ 可执行文件 |

#### macOS 使用方法

1. 下载 `Salu-macos-*.zip`
2. 解压后双击 `Salu.app` 即可开始游戏
3. 首次运行可能需要在"系统设置 → 隐私与安全性"中允许运行

#### Linux 使用方法

```bash
# 解压
tar -xzf salu-linux-x86_64.tar.gz

# 运行
./salu-linux-x86_64
```

#### Windows 使用方法

1. 下载 `salu-windows-x86_64.zip`
2. 解压后双击 `salu-windows-x86_64.exe` 即可开始游戏
3. 或在命令提示符/PowerShell 中运行

### 方式二：从源码构建

```bash
# 克隆仓库
git clone https://github.com/chiimagnus/salu.git
cd salu

# 运行游戏（随机种子）
swift run
```

> 需要 Swift 6.2+，可从 [swift.org](https://swift.org/download/) 下载

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
swift test
```

### 4. 提交代码

```bash
git add .
git commit -m "✨ 添加xxx功能"
git push origin feature/你的功能名
```

### 5. 创建 Pull Request

在 GitHub 上创建 PR，填写清晰的标题和描述。
