# GitHub 分支保护配置指南

本文档指导如何为 Salu 项目配置 GitHub 分支保护规则，确保 main 分支的安全性和代码质量。

---

## 📍 访问路径

1. 打开 GitHub 仓库页面：https://github.com/chiimagnus/salu
2. 点击 **Settings**（设置）
3. 在左侧菜单找到 **Rules** → **Rulesets**

---

## ✅ 已配置的规则

你已经创建了 "Protect main" 规则集，包含以下规则：

| 规则 | 状态 | 作用 |
|------|------|------|
| Restrict deletions | ✅ 已启用 | 防止删除 main 分支 |
| Block force pushes | ✅ 已启用 | 防止强制推送覆盖历史 |

---

## 🔧 推荐添加的规则

### 规则 1：Require a pull request before merging

**作用**：所有代码必须通过 Pull Request 合并，不能直接 push 到 main。

**配置步骤**：

1. 在 Rulesets 页面点击 **"Protect main"** 进入编辑
2. 滚动到 **"Rules"** 部分
3. 找到并启用 **"Require a pull request before merging"**
4. 配置选项：

   | 选项 | 推荐设置 | 说明 |
   |------|----------|------|
   | Required approvals | **0** | 你自己可以直接合并（无需他人审批） |
   | Dismiss stale reviews | ☐ 不勾选 | 个人项目不需要 |
   | Require review from code owners | ☐ 不勾选 | 没有 CODEOWNERS 文件 |
   | Require approval of most recent push | ☐ 不勾选 | 个人项目不需要 |
   | Require conversation resolution | ☐ 可选 | PR 评论需全部解决才能合并 |

5. 点击 **Save changes**

---

### 规则 2：Require status checks to pass

**作用**：PR 合并前必须通过 CI 测试（GitHub Actions）。

**配置步骤**：

1. 在 Rulesets 页面点击 **"Protect main"** 进入编辑
2. 滚动到 **"Rules"** 部分
3. 找到并启用 **"Require status checks to pass"**
4. 配置选项：

   | 选项 | 推荐设置 | 说明 |
   |------|----------|------|
   | Require branches to be up to date | ☑ 勾选 | 合并前需与 main 同步 |

5. 在 **"Status checks that are required"** 中添加：
   - 点击搜索框，输入 `test`
   - 选择 **"test (ubuntu-latest)"**（必须）
   - 可选添加 **"test (macos-latest)"** 和 **"test (windows-latest)"**

   > ⚠️ **注意**：如果搜索不到，需要先创建一个 PR 触发一次 CI，之后就会出现在列表中。

6. 点击 **Save changes**

---

## 📋 完整配置清单

配置完成后，你的 "Protect main" 规则集应包含：

```
✅ Restrict deletions
✅ Block force pushes
✅ Require a pull request before merging
   └─ Required approvals: 0
✅ Require status checks to pass
   └─ Require branches to be up to date: ✓
   └─ Required checks: test (ubuntu-latest)
```

---

## 🔄 日常开发流程

配置完成后，你的开发流程将是：

```
1. 创建功能分支
   git checkout -b feature/xxx

2. 开发并提交
   git add .
   git commit -m "feat: xxx"

3. 推送分支
   git push origin feature/xxx

4. 在 GitHub 创建 Pull Request
   - 填写 PR 标题和描述
   - 等待 CI 测试通过（绿色 ✓）

5. 合并 PR
   - 点击 "Merge pull request" 或 "Squash and merge"
   - 删除功能分支（可选）

6. 更新本地 main
   git checkout main
   git pull origin main
```

---

## ❓ 常见问题

### Q1: 如果我直接 push 到 main 会怎样？

**A**: 会被拒绝，显示类似错误：
```
remote: error: GH006: Protected branch update failed
remote: error: Required status check "test" is expected
```

### Q2: 如何绕过保护规则？

**A**: 在紧急情况下，你可以：
1. 进入 Settings → Rulesets → Protect main
2. 在 **"Bypass list"** 中添加自己
3. 完成紧急修复后，建议移除绕过权限

### Q3: 能否允许某些情况直接 push？

**A**: 可以通过 **"Bypass list"** 添加特定用户或团队，但不推荐，因为这会削弱保护效果。

### Q4: CI 测试一直不过怎么办？

**A**: 
1. 查看 GitHub Actions 页面的错误日志
2. 本地运行测试：`./.cursor/Scripts/test_game.sh`
3. 修复后再次 push 更新 PR

---

## 🎯 可选的高级规则

以下规则根据需要启用：

### Require linear history（保持线性历史）

- **作用**：禁止 merge commit，只允许 rebase 或 squash
- **效果**：`git log --oneline` 显示干净的线性历史
- **适用**：喜欢整洁历史记录的开发者

### Require signed commits（要求签名提交）

- **作用**：所有提交必须使用 GPG 签名
- **效果**：提交旁边显示 "Verified" 徽章
- **适用**：对安全性要求较高的项目

---

## 📊 规则对比

| 规则 | 个人项目 | 团队项目 |
|------|----------|----------|
| Restrict deletions | ✅ 推荐 | ✅ 必须 |
| Block force pushes | ✅ 推荐 | ✅ 必须 |
| Require PR | ✅ 推荐 | ✅ 必须 |
| Require status checks | ✅ 推荐 | ✅ 必须 |
| Require approvals | ⚪ 可选(0) | ✅ 必须(≥1) |
| Require linear history | ⚪ 可选 | ⚪ 可选 |
| Require signed commits | ⚪ 可选 | ⚪ 可选 |

---

## 🔗 参考链接

- [GitHub 官方文档 - 管理规则集](https://docs.github.com/cn/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub 官方文档 - 保护分支](https://docs.github.com/cn/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

