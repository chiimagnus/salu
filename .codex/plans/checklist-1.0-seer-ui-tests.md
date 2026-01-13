# Salu 1.0 占卜家序列（P1–P7）UI 测试核对清单

> 目的：让“占卜家序列”相关功能在 CLI 中**可验收、可复现**。  
> 覆盖范围：P1～P7（并补充 P0“疯狂”在 UI 中的可见性，因为它是占卜家序列的前置核心）。  
> 备注：1.0 的“预知”采用**简化版（自动选牌）**，不会出现“玩家从 N 张中手动选择”的交互。

---

## 0. 预备（强烈建议）

### 0.1 隔离数据目录（避免旧存档/旧设置干扰）

建议每次验收都显式设置 `SALU_DATA_DIR`：

```bash
export SALU_DATA_DIR=/tmp/salu-ui-seer
rm -rf "$SALU_DATA_DIR"
mkdir -p "$SALU_DATA_DIR"
```

### 0.2 构建与全量测试（冒烟）

```bash
swift build
swift test
```

---

## 1. 你“在 CLI 看不到占卜家效果”的最常见原因（先排除）

- [ ] **没开日志面板**：战斗里很多关键提示（如“预知选择了哪张牌”“回溯了哪张牌”“疯狂阈值触发”）都在“日志面板”里；默认可能是关闭的。  
  - 开启路径：主菜单 → `设置` → `日志显示`（切到“开启”）。
- [ ] **开了 `SALU_TEST_MODE=1` 但战斗牌组被压缩**：测试模式默认把战斗牌组替换成“仅 1 张打击”，所以你几乎不可能在战斗中看到占卜家卡牌/预知/回溯/清理疯狂等效果。  
  - 解决：用 `SALU_TEST_BATTLE_DECK=seer`（P1 核心牌）或 `SALU_TEST_BATTLE_DECK=seer_p7`（含 P7 新牌）注入占卜家验收牌组（见 §2 / §9）。
- [ ] **测试模式下敌人 HP 默认被压缩为 1**：这会导致 Boss 很难进入不同血量阶段，从而看不到 P6 的三阶段机制。  
  - 解决：加上 `SALU_TEST_ENEMY_HP=normal`（保留真实 HP）或 `SALU_TEST_ENEMY_HP=30`（手动验收更快）。
- [ ] **预知是“自动选牌”**：1.0 的实现不会弹出“请选择一张”的 UI；你需要通过“手牌变化 + 日志”确认。

---

## 2. P1：核心卡牌机制（预知 / 回溯 / 改写 / 清理疯狂）

### 2.1 进入“可快速验收”的战斗环境（推荐命令）

```bash
SALU_TEST_MODE=1 \
SALU_TEST_MAP=battle \
SALU_TEST_BATTLE_DECK=seer \
swift run GameCLI --seed 1
```

核对点：
- [ ] 标题栏出现“🧪测试模式”标记。
- [ ] 进入战斗后，手牌中能在 1～2 个回合内看到占卜家卡（如：灵视/真相低语/冥想/命运改写/时间碎片）。

> 提示：测试模式下敌人 `HP=1`，**不要急着打出攻击牌**（真相低语）把战斗打结束；先把机制验收完再收尾。

### 2.2 P1-预知（`foresight`）核对

步骤：
- [ ] 在战斗中打出 `灵视` 或 `真相低语`。

预期（至少满足其一）：
- [ ] **手牌变化**：手牌数量会因为“预知选牌入手”而增加（通常在结算后能看到新增的那张牌）。
- [ ] **日志（若开启）**：出现类似“预知 N 张，选择 XXX 入手”的日志。

额外核对（边界）：
- [ ] 当抽牌堆为空时打出预知牌：预知不会生效（当前实现不会自动“弃牌堆洗回抽牌堆”再预知）。

### 2.3 P1-回溯（`rewind`）核对

步骤：
- [ ] 先打出任意 1 张牌（保证弃牌堆里已有牌）。
- [ ] 再打出 `时间碎片`。

预期：
- [ ] 手牌出现“从弃牌堆回来的那张牌”（被回溯的牌回到手里）。
- [ ] 日志（若开启）出现类似“回溯 XXX 回到手牌”。
- [ ] 现象解释：`时间碎片`的“回溯”发生在它自己进入弃牌堆之前，所以回溯到手的不会是“时间碎片自身”。

### 2.4 P1-清理疯狂（`clearMadness`）核对

步骤：
- [ ] 通过打出 `灵视/真相低语/命运改写/时间碎片` 让自己获得若干层“疯狂”。
- [ ] 打出 `冥想`。

预期：
- [ ] 玩家状态栏出现 `🌀疯狂X`，且 `冥想` 后层数减少。
- [ ] 日志（若开启）出现“疯狂消除 N 层”。

### 2.5 P1-改写意图（`rewriteIntent`）核对

步骤：
- [ ] 观察敌人“📢 意图”行（先记下原意图）。
- [ ] 打出 `命运改写`（单敌人时不需要手动选目标；多敌人时按提示输入“卡牌序号 目标序号”）。

预期：
- [ ] 敌人“📢 意图”变为 `🛡️ 防御（被改写）`（或同等含义文本）。
- [ ] 日志（若开启）出现“改写 XXX 的意图：旧 → 新”。

---

## 3. P0：疯狂系统（UI 可见性 + 阈值提示）

### 3.1 疯狂状态显示（Battle UI）

步骤：
- [ ] 在 §2 的战斗环境中，连续打出 2～3 张会加疯狂的牌。

预期：
- [ ] 玩家状态行出现 `🌀疯狂`，并随层数变化。
- [ ] 颜色随阈值变化（暗淡 / 黄色 / 红色 / 红色加粗）。

### 3.2 疯狂阈值事件（可选，依赖日志）

步骤：
- [ ] 通过连续加疯狂将层数堆到 ≥3、≥6、≥10（测试模式下可以多回合慢慢堆）。

预期：
- [ ] 日志（若开启）出现“疯狂阈值 N 触发：……”的提示。

---

## 4. P2：敌人意图扩展（UI）

### 4.1 注册与池子可见性（推荐走“资源管理 UI”，稳定不依赖 RNG）

路径：主菜单 → `设置` → `资源管理（池子/注册表）`

核对点：
- [ ] Act2 精英池中能看到 `疯狂预言者（mad_prophet）`、`时间守卫（time_guardian）`。
- [ ] Act2 Boss 为 `赛弗（cipher）`。

### 4.2 实战意图展示（可选，较慢但更贴近体验）

步骤（建议测试模式加速）：
- [ ] `SALU_TEST_MODE=1 SALU_TEST_MAP=mini SALU_TEST_MAX_FLOOR=3 swift run GameCLI --seed <任意>` 开始新冒险。
- [ ] 通过 Act1 → 进入 Act2 → 找到精英节点，观察敌人是否为“疯狂预言者/时间守卫”，并确认其意图图标与文本符合设计（例如“精神冲击”等）。
- [ ] 进入 Act2 Boss 节点，确认 Boss 名称为“赛弗”。

---

## 5. P3：占卜家遗物（UI）

### 5.1 注册可见性（资源管理 UI）

路径：主菜单 → `设置` → `资源管理（池子/注册表）` → 遗物列表

核对点（至少能看到以下遗物）：
- [ ] 第三只眼（`third_eye`）
- [ ] 破碎怀表（`broken_watch`）
- [ ] 理智之锚（`sanity_anchor`）
- [ ] 深渊之瞳（`abyssal_eye`）
- [ ] 预言者手札（`prophet_notes`）
- [ ] 疯狂面具（`madness_mask`）

### 5.2 功能验收（推荐：走 P5 事件拿“破碎怀表”）

步骤：
- [ ] 先按 §7.2（P5-时间裂隙）获得“破碎怀表”。
- [ ] 再进入任意战斗，打出 `灵视/真相低语`，观察“每回合首次预知额外 +1”是否生效（需要日志面板更好判断）。

---

## 6. P4：商店扩展（12 格 + 消耗品）

启动：

```bash
SALU_TEST_MODE=1 SALU_TEST_MAP=shop swift run GameCLI --seed 1
```

核对点：
- [ ] 商店界面分为：卡牌 / 遗物 / 消耗品 / 删牌服务（`D`）。
- [ ] 输入支持：`1..` 买卡、`R1..` 买遗物、`C1..` 买消耗品、`D` 进入删牌、`0` 离开。
- [ ] 当金币不足时，购买应失败并提示。
- [ ] 当消耗品槽位满（最多 3 个）时，继续购买消耗品应失败并提示。

可选（验证“接入存档”）：
- [ ] 购买任意消耗品后，退出到主菜单；检查 `SALU_DATA_DIR/run_save.json` 中 `consumableIds` 是否包含对应 ID。

---

## 7. P5：占卜家专属事件（UI）

> 事件出现由 seed 决定。推荐直接跑已有黑盒 UI 测试（§7.4），它会自动穷举找到能命中指定事件的 seed。

### 7.1 事件 UI 通用核对（进入事件房间）

核对点：
- [ ] 标题、图标、描述文本完整显示（中文）。
- [ ] 至少 3 个选项，输入 `1/2/3` 可选择。
- [ ] 选择后出现“结果摘要”（含疯狂变化、获得卡牌/遗物等）。

### 7.2 事件：时间裂隙（`seer_time_rift`）

核对点：
- [ ] 选项“窥视未来”会获得遗物“破碎怀表”，并使疯狂 +2（结果摘要可见）。
- [ ] 选项“窥视过去”在存在可升级卡时，会进入“升级二次选择”流程（follow-up UI）。

### 7.3 事件：疯狂预言者（`seer_mad_prophet`）

核对点：
- [ ] 选项“聆听预言”会获得卡牌“深渊凝视”，并使疯狂 +4（结果摘要可见）。
- [ ] 选项“打断他”会进入精英战（疯狂预言者）。

### 7.4 自动化黑盒 UI 测试（推荐作为 P5 验收主入口）

```bash
swift test --filter GameCLISeerEventUITests
```

核对点：
- [ ] 测试全部通过。
- [ ] 会在临时 `SALU_DATA_DIR` 下落盘存档，并验证：遗物/卡牌/疯狂写入正确。

---

## 8. P6：赛弗 Boss 特殊机制（UI）

### 8.1 推荐启动命令（测试模式但保留真实 HP）

```bash
SALU_TEST_MODE=1 \
SALU_TEST_MAP=mini \
SALU_TEST_MAX_FLOOR=3 \
SALU_TEST_ENEMY_HP=normal \
SALU_TEST_BATTLE_DECK=seer_p7 \
swift run GameCLI --seed 1
```

核对点：
- [ ] 第 2 幕 Boss 为 `赛弗（cipher）`。
- [ ] 阶段 1（HP > 60%）能看到意图 `预知反制：下回合预知 -1`。
- [ ] 赛弗使用“预知反制”后，你下回合打出 `灵视`（预知 2），日志显示 `预知 1 张`（或同等含义）。
- [ ] 将赛弗压到 ≤60% HP 后，能看到意图 `命运剥夺：弃牌 2 + 疯狂 +2`，并在你下一回合抽牌后自动弃置 2 张手牌。
- [ ] 将赛弗压到 ≤30% HP 后，能看到意图 `命运改写：下回合首牌费用 +1`，且你下一回合手牌费用会显示为 `◆1（原0）` 等（直到打出第一张牌）。
- [ ] 能看到意图 `时间回溯：回复 15 HP`，并在血条上观察到回复。

> 提示：想更快进入阶段，可用 `SALU_TEST_ENEMY_HP=30`（Boss 更容易压到 60%/30% 阈值）。

---

## 9. P7：卡牌池扩展（罕见/稀有）

### 9.1 注册表可见性（资源管理 UI）

路径：主菜单 → `设置` → `资源管理（池子/注册表）` → 卡牌列表

核对点：
- [ ] `净化仪式（purification_ritual）`：罕见，费用 2。
- [ ] `预言回响（prophecy_echo）`：罕见，费用 1。
- [ ] `序列共鸣（sequence_resonance）`：稀有，费用 3。

### 9.2 战斗内功能验收（推荐命令）

```bash
SALU_TEST_MODE=1 \
SALU_TEST_MAP=battle \
SALU_TEST_BATTLE_DECK=seer_p7 \
swift run GameCLI --seed 1
```

核对点：
- [ ] 打出 `序列共鸣` 后，玩家状态行出现 `〰️序列共鸣+1`。
- [ ] 之后打出 `灵视/真相低语`，玩家立即获得对应格挡（看格挡数变化 + 日志）。
- [ ] 同一回合至少触发 2 次预知后打出 `预言回响`，日志里显示伤害为 `3 × 本回合预知次数`（例如应为 6）。
- [ ] 先通过预知堆出若干 `🌀疯狂`，再打出 `净化仪式`：疯狂归零（日志有“疯狂消除 N 层”），并随机弃置 1 张手牌。

---

## 10. 对应实现/测试位置（追溯用）

- P1（BattleEffect/卡牌定义/引擎执行）：`Sources/GameCore/Kernel/BattleEffect.swift`、`Sources/GameCore/Battle/BattleEngine.swift`、`Sources/GameCore/Cards/Definitions/Seer/SeerCards.swift`
- P0（疯狂定义 + UI）：`Sources/GameCore/Status/Definitions/Debuffs.swift`、`Sources/GameCLI/Screens/BattleScreen.swift`
- P2（敌人）：`Sources/GameCore/Enemies/Definitions/Act2/*`、`Sources/GameCore/Enemies/Act2EnemyPool.swift`
- P3（遗物）：`Sources/GameCore/Relics/Definitions/SeerRelics.swift`
- P4（商店/消耗品/存档）：`Sources/GameCore/Consumables/*`、`Sources/GameCore/Shop/*`、`Sources/GameCLI/Screens/ShopScreen.swift`、`Sources/GameCLI/Persistence/SaveService.swift`
- P5（事件）：`Sources/GameCore/Events/Definitions/SeerEvents.swift`、`Sources/GameCLI/Rooms/Handlers/EventRoomHandler.swift`、`Tests/GameCLIUITests/GameCLISeerEventUITests.swift`
- P6（赛弗 Boss 机制 + 费用显示）：`Sources/GameCore/Kernel/BattleEffect.swift`、`Sources/GameCore/Battle/BattleEngine.swift`、`Sources/GameCore/Enemies/Definitions/Act2/Act2BossEnemies.swift`、`Sources/GameCLI/Screens/BattleScreen.swift`、`Tests/GameCoreTests/CipherBossMechanicsTests.swift`
- P7（新卡牌/状态 + 测试牌组）：`Sources/GameCore/Cards/Definitions/Seer/SeerCards.swift`、`Sources/GameCore/Cards/CardRegistry.swift`、`Sources/GameCore/Status/Definitions/Buffs.swift`、`Sources/GameCore/Status/StatusRegistry.swift`、`Sources/GameCLI/TestMode.swift`、`Tests/GameCoreTests/SeerAdvancedCardsTests.swift`
