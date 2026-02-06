# SaluAVP（visionOS）卡牌可读性 + 端详（peek）+ 牌堆 UX 实施计划

> 执行方式：建议使用 `executing-plans` 按批次实现与验收（每批 2–4 个 task）。

**Goal（目标）**
- 在 visionOS Simulator 上，战斗时的 3D 手牌像“现实卡牌”一样可读：卡面直接显示文字（非 HUD 列表）。
- 提供一个仅包含 `DisplayMode(A/B/C/D)` 的设置入口（2D 控制面板），动态影响卡面显示内容，默认 **C**。
- 增加“端详/peek”：按住卡牌 → 卡牌吸到眼前放大；松开 → 回到手牌（不打断出牌节奏）。
- 补齐牌堆信息：抽牌堆 / 弃牌堆 / 消耗堆（exhaust）至少可见计数，并逐步提供 3D 交互呈现。

**Non-goals（非目标）**
- 本阶段不做：甩牌/投掷命中、复杂物理、写实材质/VFX、卡牌插画、多人/多敌人目标选择增强。
- 不把任何 UI/RealityKit 代码下沉到 `Sources/`（GameCore 仍保持纯逻辑）。

**Approach（方案 / Plan A）**
- 卡面文本渲染：用 `UIGraphicsImageRenderer`（或 CoreGraphics）把 `CardDefinition` 的文本渲染成 `CGImage`，再用 `TextureResource` 生成纹理并贴到卡牌正面材质上。
- 性能：做 texture cache（key 包含 `cardId + language + displayMode`），并避免 `RealityView.update` 每帧重复重建手牌。
- 端详交互：Simulator 先做 `press-and-hold`（按住进入端详，松开退出），保留 `tap` 作为“出牌”。
- 牌堆 UX：先 HUD 计数（P3.1），再加 3D 牌堆实体与交互（P3.2+）。

**Acceptance（验收）**
1. 控制面板可切换 DisplayMode（A/B/C/D），战斗手牌卡面文字随之变化。
2. DisplayMode 默认是 **C**：卡名 + 费用 + 类型 + 简短描述（1–2 行）。
3. 按住卡牌会进入端详（卡牌靠近并放大），松开回到手牌；端详时仍遵循当前 DisplayMode。
4. Battle HUD 至少显示：`Draw/Discard/Exhaust` 三个计数。
5.（P3.2 完成后）场景内出现 3 个 3D 牌堆实体，位置稳定、可读、计数正确。

**Build / Verify（每批至少一次）**
```bash
xcodebuild -project SaluNative/SaluNative.xcodeproj \
  -scheme SaluAVP \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro' \
  build
```

---

## Plan A（主方案）

### P1：卡面可读（DisplayMode + 卡面纹理渲染）

#### Task 1：接入 DisplayMode（控制面板 → Immersive）

**Files:**
- Modify: `SaluNative/SaluAVP/AppModel.swift`（新增 `cardDisplayMode`，默认 `.modeC`）
- Create: `SaluNative/SaluAVP/CardDisplayMode.swift`
- Modify: `SaluNative/SaluAVP/ControlPanel/ControlPanelView.swift`（分段选择器）
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`（读取 `AppModel.cardDisplayMode` 并影响卡面渲染）

**Steps:**
1) 在控制面板新增 `Picker(.segmented)` 切换 `DisplayMode`（A/B/C/D）。
2) `ImmersiveRootView` 通过 `@Environment(AppModel.self)` 获取 mode，并传入 `makeCardEntity(...)`。

**Verify:**
- Build: `xcodebuild ... build`
- Manual（Simulator）：切换 DisplayMode 后进入战斗，观察手牌显示内容变化（后续 Task 2/3 完成后可验证）。

> 注：如果此 Task 已在当前分支实现，可标记为 ✅ Done 并直接进入 Task 2。

#### Task 2：实现 CardFace 渲染器（文本 → CGImage）

**Files:**
- Create: `SaluNative/SaluAVP/Immersive/CardFaceRenderer.swift`（或 `.../Rendering/CardFaceRenderer.swift`）

**Requirements:**
- 输入：`card: GameCore.Card` + `def: any CardDefinition.Type` + `displayMode: CardDisplayMode` + `language: GameLanguage`
- 输出：`CGImage`（或 `UIImage`，最终能转成 `CGImage`）
- 排版规则：
  - Mode A：仅卡名
  - Mode B：卡名 + 费用（左上）
  - Mode C：卡名 + 费用 + 类型 + 简短规则（最多 2 行，超出截断）
  - Mode D：卡名 + 费用 + 类型 + 完整 `rulesText`（多行换行）
- 字体与对比度：在 Simulator 环境下可读（优先大字号 + 高对比）。

**Verify:**
- Build: `xcodebuild ... build`
- Manual：进入战斗时，至少能看到 Mode A/B 的卡名/费用正确显示。

#### Task 3：卡面纹理缓存 + 贴图到 3D 卡牌正面

**Files:**
- Create: `SaluNative/SaluAVP/Immersive/CardFaceTextureCache.swift`（cache：key → `TextureResource`）
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`（`makeCardEntity` 使用 texture material）

**Steps:**
1) 设计 cache key：`cardId.rawValue + language.rawValue + displayMode.rawValue`（必要时加 `isUpgraded` 等）。
2) `makeCardEntity`：
   - 生成 card box mesh（保持当前尺寸）
   - materials：正面用 `UnlitMaterial`（或等价）贴 `TextureResource`；背面/侧面可用纯色材质
   - `isPlayable`：用整体 `opacity` 或叠加 tint（避免为“可用/不可用”各做一套纹理）
3) 避免每帧重建：
   - 增加 `renderHand` 的“手牌签名”判断（例如 `hand.map(\\.cardId)` + `playableSet` + `displayMode`），签名不变则不重建手牌实体。

**Verify:**
- Build: `xcodebuild ... build`
- Manual：
  - 进入战斗后卡面清晰可读
  - 切换 DisplayMode 后卡面更新
  - 观察性能：不应出现明显卡顿（签名不变时不应每帧重建）

---

### P2：端详/Peek（按住吸到眼前，松开返回）

#### Task 4：为卡牌添加 “press-and-hold peek” 手势（Simulator 可用）

**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`

**Design:**
- `tap`：保持现状（出牌）
- `press-and-hold`：
  - begin：把目标卡牌复制/临时移动到 head-relative 的 inspect anchor（更靠近相机 + 放大）
  - end：还原回手牌
  - 端详期间禁止触发出牌（避免长按被识别成点击）

**Implementation notes:**
- 优先使用 targeted gesture（能拿到 `value.entity`），并只对 `name` 以 `card:` 开头的实体生效。
- Inspect 实体建议为“clone”，避免破坏手牌排布；release 时直接移除 clone。

**Verify:**
- Build: `xcodebuild ... build`
- Manual（Simulator）：
  - 按住某张卡：卡牌吸到眼前放大并保持可读
  - 松开：卡牌回到手牌位置
  - 单击：仍然能正常出牌

---

### P3：抽牌堆/弃牌堆/消耗堆（信息可见 + 3D 牌堆）

#### Task 5：Battle HUD 显示 draw/discard/exhaust 计数（最小闭环）

**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/BattleHUDPanel.swift`

**Steps:**
1) 在 HUD 的战斗信息区域追加一行（或两行）：
   - `Draw X  Discard Y  Exhaust Z`
2) 数据源来自 `BattleState`：`drawPile.count / discardPile.count / exhaustPile.count`

**Verify:**
- Build: `xcodebuild ... build`
- Manual：战斗中计数随抽牌/弃牌/消耗变化（至少在出牌/结束回合后有变化）。

#### Task 6：添加 3D 牌堆实体（3 个堆 + 可读计数）

**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Create (optional): `SaluNative/SaluAVP/Immersive/PileEntityFactory.swift`

**Design:**
- 3 个堆：Draw / Discard / Exhaust
- 位置：靠近手牌但不遮挡（例如手牌左右两侧 + 稍远）
- 外观：简易“卡堆”盒体或叠卡，顶部有计数贴图
- 交互（第一版）：可点选高亮（后续可扩展为长按端详堆内容）

**Verify:**
- Build: `xcodebuild ... build`
- Manual：计数正确、位置稳定、不会遮挡 HUD/手牌。

#### Task 7（可选）：端详牌堆（按住显示 Top-N 卡名列表）

**Files:**
- Modify: `SaluNative/SaluAVP/Immersive/ImmersiveRootView.swift`
- Modify/Create: `SaluNative/SaluAVP/Immersive/PilePeekPanel.swift`（Attachment 或纹理卡片）

**Scope (MVP):**
- 按住 draw/discard/exhaust 堆 → 弹出一个小面板（或吸到眼前）显示前 N 张卡名（N=5/10）
- 仍遵循当前 DisplayMode（只显示允许的信息密度）

**Verify:**
- Build: `xcodebuild ... build`
- Manual：按住牌堆能看到列表，松开关闭，不影响出牌。

---

## Open Questions（不确定项，执行前确认）

1) 语言：卡面文本默认用 `zhHans` 是否固定？还是未来需要跟随系统语言？
2) Mode C 的“简短描述”：
   - 直接截断 `rulesText` 的前 1–2 行即可（MVP）？
   - 还是需要为卡牌定义新增单独的 `shortRulesText`（会涉及 GameCore 变更）？

## Rollup / 回归策略

- 每完成一个 Phase（P1/P2/P3）后至少跑一次 `xcodebuild ... build`。
- 若 P3 增加了对 `BattleState` 的新读取逻辑或任何 GameCore 变更，则补跑：`swift test`。

