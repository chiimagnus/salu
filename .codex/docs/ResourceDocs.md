═══════════════════════════════════════════════
  📦 资源管理（内容与池子一览）
═══════════════════════════════════════════════

🃏 卡牌（Registry）
  总数：34  |  攻击：14  技能：16  能力：4

  ⚔️ 攻击牌（14）
    - 深渊凝视  (abyssal_gaze)  ◆2  稀有
    - 深渊凝视+  (abyssal_gaze+)  ◆2  稀有
    - 深渊重锤  (bash)  ◆2  起始
    - 深渊重锤+  (bash+)  ◆2  起始
    - 裂隙横断  (cleave)  ◆1  普通
    - 窒息缠绕  (clothesline)  ◆2  普通
    - 腐蚀之触  (poisoned_strike)  ◆1  普通
    - 触须鞭笞  (pommel_strike)  ◆1  普通
    - 预言回响  (prophecy_echo)  ◆1  罕见
    - 预言回响+  (prophecy_echo+)  ◆1  罕见
    - 凝视之触  (strike)  ◆1  起始
    - 凝视之触+  (strike+)  ◆1  起始
    - 真相低语  (truth_whisper)  ◆1  普通
    - 真相低语+  (truth_whisper+)  ◆1  普通

  🛡️ 技能牌（16）
    - 灰雾护盾  (defend)  ◆1  起始
    - 灰雾护盾+  (defend+)  ◆1  起始
    - 命运改写  (fate_rewrite)  ◆1  罕见
    - 命运改写+  (fate_rewrite+)  ◆1  罕见
    - 疯狂低语  (intimidate)  ◆1  普通
    - 冥想  (meditation)  ◆1  普通
    - 冥想+  (meditation+)  ◆1  普通
    - 净化仪式  (purification_ritual)  ◆2  罕见
    - 净化仪式+  (purification_ritual+)  ◆2  罕见
    - 理智燃烧  (sanity_burn)  ◆1  普通
    - 理智燃烧+  (sanity_burn+)  ◆1  普通
    - 躯壳硬化  (shrug_it_off)  ◆1  普通
    - 灵视  (spirit_sight)  ◆0  普通
    - 灵视+  (spirit_sight+)  ◆0  普通
    - 时间碎片  (time_shard)  ◆1  罕见
    - 时间碎片+  (time_shard+)  ◆1  罕见

  ✨ 能力牌（4）
    - 虚空步  (agile_stance)  ◆1  普通
    - 禁忌献祭  (inflame)  ◆1  普通
    - 序列共鸣  (sequence_resonance)  ◆3  稀有
    - 序列共鸣+  (sequence_resonance+)  ◆3  稀有


🧬 状态（StatusRegistry）
  总数：8

  - ⚡敏捷  (dexterity)  正面  不递减  出伤:-  入伤:-  格挡:add  prio:0
  - 🥀脆弱  (frail)  负面  回合结束 -1  出伤:-  入伤:-  格挡:mul  prio:100
  - 🌀疯狂  (madness)  负面  不递减  出伤:-  入伤:mul  格挡:-  prio:200
  - ☠️中毒  (poison)  负面  回合结束 -1  出伤:-  入伤:-  格挡:-  prio:0
  - 〰️序列共鸣  (sequence_resonance)  正面  不递减  出伤:-  入伤:-  格挡:-  prio:0
  - 💪力量  (strength)  正面  不递减  出伤:add  入伤:-  格挡:-  prio:0
  - 💔易伤  (vulnerable)  负面  回合结束 -1  出伤:-  入伤:mul  格挡:-  prio:100
  - 😵虚弱  (weak)  负面  回合结束 -1  出伤:mul  入伤:-  格挡:-  prio:100


🧪 消耗品（ConsumableRegistry）
  已注册：4  |  商店池：4

  - 🛡️格挡药剂  (block_potion)  普通  战斗内可用  战斗外不可用
    淡蓝色的药液，喝下后皮肤短暂硬化。获得 12 点格挡。
  - 🧪治疗药剂  (healing_potion)  普通  战斗内可用  战斗外可用
    暗红色的液体，带着铁锈般的腥味。恢复 20 点生命值。
  - 📿净化符文  (purification_rune)  罕见  战斗内可用  战斗外不可用
    符文燃烧的瞬间，所有杂念都随之消散。清除所有疯狂。
  - 💪力量药剂  (strength_potion)  罕见  战斗内可用  战斗外不可用
    深红色的浓稠液体，散发着血腥的气息。获得 2 点力量。


🧭 事件（EventRegistry）
  总数：6

  - 🗿序列祭坛  (altar)
  - 👻流浪者的低语  (scavenger)
  - 🔮疯狂预言者  (seer_mad_prophet)
  - 📚序列密室  (seer_sequence_chamber)
  - ⏳时间裂隙  (seer_time_rift)
  - 🤝尼古拉的指导  (training)


👹 敌人池/遭遇池（Act1/Act2/Act3）

Act1 敌人池
  普通敌人（weak）数量：6
  精英敌人（medium）数量：2

  普通敌人（weak）
    - 虔信者  (cultist)
    - 咀嚼者  (jaw_worm)
    - 翠鳞虫  (louse_green)
    - 血眼虫  (louse_red)
    - 溶蚀幼崽  (slime_small_acid)
    - 腐菌体  (spore_beast)

  精英敌人（medium）
    - 深渊黏体  (slime_medium_acid)
    - 沉默守墓人  (stone_sentinel)

🧩 遭遇池（Act1EncounterPool.weak）
  总遭遇数：10  |  双敌人遭遇：4（约 40%）

    [1] 咀嚼者
    [2] 虔信者
    [3] 翠鳞虫
    [4] 血眼虫
    [5] 腐菌体
    [6] 溶蚀幼崽
    [7] 翠鳞虫 + 血眼虫
    [8] 虔信者 + 虔信者
    [9] 咀嚼者 + 翠鳞虫
    [10] 腐菌体 + 溶蚀幼崽

Act2 敌人池
  普通敌人（weak）数量：2
  精英敌人（medium）数量：3

  普通敌人（weak）
    - 铭文傀儡  (clockwork_sentinel)
    - 虚影猎手  (shadow_stalker)

  精英敌人（medium）
    - 疯狂预言者  (mad_prophet)
    - 符文执行者  (rune_guardian)
    - 时间守卫  (time_guardian)

  Boss（Act2）
    - 赛弗  (cipher)

🧩 遭遇池（Act2EncounterPool.weak）
  总遭遇数：4  |  双敌人遭遇：2（约 50%）

    [1] 虚影猎手
    [2] 铭文傀儡
    [3] 虚影猎手 + 铭文傀儡
    [4] 铭文傀儡 + 铭文傀儡

Act3 敌人池
  普通敌人（weak）数量：2
  精英敌人（medium）数量：1

  普通敌人（weak）
    - 梦境寄生者  (dream_parasite)
    - 虚无行者  (void_walker)

  精英敌人（medium）
    - 循环守卫  (cycle_guardian)

🧩 遭遇池（Act3EncounterPool.weak）
  总遭遇数：5  |  双敌人遭遇：3（约 60%）

    [1] 虚无行者
    [2] 梦境寄生者
    [3] 虚无行者 + 梦境寄生者
    [4] 梦境寄生者 + 梦境寄生者
    [5] 虚无行者 + 虚无行者

📚 EnemyRegistry（全部已注册敌人）
  总数：19

    - 赛弗  (cipher)
    - 铭文傀儡  (clockwork_sentinel)
    - 虔信者  (cultist)
    - 循环守卫  (cycle_guardian)
    - 梦境寄生者  (dream_parasite)
    - 咀嚼者  (jaw_worm)
    - 翠鳞虫  (louse_green)
    - 血眼虫  (louse_red)
    - 疯狂预言者  (mad_prophet)
    - 符文执行者  (rune_guardian)
    - 序列始祖  (sequence_progenitor)
    - 虚影猎手  (shadow_stalker)
    - 深渊黏体  (slime_medium_acid)
    - 溶蚀幼崽  (slime_small_acid)
    - 腐菌体  (spore_beast)
    - 沉默守墓人  (stone_sentinel)
    - 时间守卫  (time_guardian)
    - 瘴气之主  (toxic_colossus)
    - 虚无行者  (void_walker)

🏺 遗物（Registry）
  已注册：13  |  可掉落（排除起始）：12

  起始（1）
    - 🔥永燃心脏  (burning_blood)  不死者的馈赠。战斗胜利后恢复 6 点生命值

  普通（5）
    - ⏱️破碎怀表  (broken_watch)  时间在这里断裂——又在这里重叠。每回合首次预知时，额外预知 1 张。
    - 🛡️鳞甲残片  (iron_bracer)  沉睡巨兽的鳞片。每次打出攻击牌，获得 2 点格挡。
    - 🏮幽冥灯火  (lantern)  照亮彼岸之路。战斗开始时获得 1 点能量。
    - 👁️第三只眼  (third_eye)  闭上双眼，才能看见真相。战斗开始时预知 2。
    - 💎远古骨锤  (vajra)  古神遗骸制成。战斗开始时获得 1 点力量。

  罕见（4）
    - 🔮深渊之瞳  (abyssal_eye)  深渊赠予你洞察——代价是它也在注视你。战斗开始时预知 3，+1 疯狂。
    - 🪶夜鸦羽翼  (feather_cloak)  来自无名之鸟。战斗开始时获得 1 点敏捷。
    - 📜预言者手札  (prophet_notes)  前人的智慧刻在纸上——墨迹下藏着血泪。每场战斗首次使用改写时，不获得疯狂。
    - ⚓理智之锚  (sanity_anchor)  抓住这根锚链——它是你最后的理智。所有疯狂阈值 +3。

  稀有（2）
    - 🎭疯狂面具  (madness_mask)  戴上它，你会失去理智——也会获得力量。当疯狂 ≥6 时，攻击伤害 +50%。
    - 🚩血誓旗帜  (war_banner)  浸染无数亡魂。战斗开始时获得 2 点力量。

  Boss（1）
    - 🧪始祖碎片  (colossus_core)  序列始祖的一部分。战斗开始时，使所有敌人获得中毒 3。
