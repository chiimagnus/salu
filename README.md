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
