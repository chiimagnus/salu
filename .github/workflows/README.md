# GitHub Actions 工作流说明

本项目包含两个 GitHub Actions 工作流，用于自动化测试和发布流程。

## 工作流列表

### 1. Tests (`.github/workflows/test.yml`)

**触发条件：**
- Push 到 `main` 或 `develop` 分支
- Pull Request 到 `main` 或 `develop` 分支

**功能：**
- 在 macOS 上运行测试
- 运行 `.cursor/Scripts/test_game.sh all`
- 上传 Debug 版本二进制文件（保留 7 天）

**Debug 构建产物：**
测试通过后，会上传 Debug 版本的可执行文件作为 Artifacts：
- `salu-debug-macos` - macOS Debug 版本

这些文件可以在 Actions 运行记录页面底部的 "Artifacts" 区域下载，用于临时调试或分享。7 天后自动删除。

**测试内容：**
- 编译测试（Debug 和 Release 模式）
- 启动测试
- 敌人系统测试
- 地图系统测试
- 集成测试（完整冒险流程）

### 2. Release (`.github/workflows/release.yml`)

**触发条件：**
- Push 版本标签（如 `v1.0.0`, `v2.1.3`）
- 手动触发（workflow_dispatch）

**功能：**
- 构建 Release 版本
- 为 macOS 创建二进制文件
- 创建 GitHub Release
- 上传构建产物

**产物：**
- `salu-macos.tar.gz` - macOS 版本

## 使用说明

### 创建发布版本

要创建新的发布版本，请使用 git 标签：

```bash
# 创建标签
git tag v1.0.0

# 推送标签到 GitHub
git push origin v1.0.0
```

这将自动触发 Release 工作流，构建并发布二进制文件。

### 手动触发发布

1. 访问仓库的 Actions 页面
2. 选择 "Release" 工作流
3. 点击 "Run workflow"
4. 选择分支并确认

### 查看工作流状态

所有工作流的状态可以在仓库的 Actions 标签页查看：
https://github.com/chiimagnus/salu/actions

## 本地测试

在推送代码前，建议先在本地运行测试：

```bash
# 运行所有测试
./.cursor/Scripts/test_game.sh all

# 快速测试
./.cursor/Scripts/test_game.sh quick

# 运行特定测试
./.cursor/Scripts/test_game.sh build
./.cursor/Scripts/test_game.sh startup
./.cursor/Scripts/test_game.sh enemy
./.cursor/Scripts/test_game.sh map
./.cursor/Scripts/test_game.sh integration
```

## 依赖项

所有工作流使用：
- **Swift 版本**: 6.2
- **Actions**: 
  - `actions/checkout@v4` - 检出代码
  - `swift-actions/setup-swift@v2` - 设置 Swift 环境
  - `actions/upload-artifact@v4` - 上传构建产物
  - `softprops/action-gh-release@v1` - 创建 GitHub Release

## 故障排除

### 工作流失败

如果工作流失败：

1. 查看工作流日志，找出失败的步骤
2. 在本地运行相同的测试脚本
3. 确保本地测试通过后再推送

### Swift 版本问题

如果需要更改 Swift 版本：

1. 更新 `Package.swift` 中的 `swift-tools-version`
2. 更新所有工作流文件中的 `swift-version` 参数

## 贡献

添加新的测试时：

1. 在 `.cursor/Scripts/tests/` 目录添加测试脚本
2. 更新 `.cursor/Scripts/test_game.sh` 以支持新测试
3. 如需要，更新工作流文件以包含新测试
