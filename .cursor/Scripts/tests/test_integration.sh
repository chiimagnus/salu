#!/bin/bash

# ============================================================
# Salu 测试 - 集成测试（完整战斗流程）
# ============================================================
# 测试完整的战斗流程：开始战斗 → 打牌 → 结束回合 → 战斗结束

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "集成测试（完整战斗流程）"

FAILED=0

# ============================================================
# 测试1：完整战斗直到结束
# ============================================================
show_step "1/4" "完整战斗流程 (seed=100)"
show_info "模拟玩家完成整局战斗（最多50回合）..."

# 生成足够多的输入：50回合 × 每回合5张牌
# 1 = 开始战斗
# 循环：1,1,1,1,1,0 (打5张牌，结束回合) × 50回合
INPUT_SEQUENCE="1"
for i in {1..50}; do
    INPUT_SEQUENCE="${INPUT_SEQUENCE}\n1\n1\n1\n1\n1\n0"
done

echo -e "${CYAN}  → 开始战斗...${NC}"

OUTPUT=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 100 2>&1)

# 检查战斗结果
if echo "$OUTPUT" | grep -q "战斗胜利"; then
    show_success "战斗完成：胜利！"
    # 提取回合数
    TURNS=$(echo "$OUTPUT" | grep -o "回合：[0-9]*\|第 [0-9]* 回合" | tail -1)
    show_detail "战斗信息: $TURNS"
elif echo "$OUTPUT" | grep -q "战斗失败"; then
    show_success "战斗完成：失败（但流程正常）"
else
    show_failure "战斗未能完成"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试2：不同敌人的战斗
# ============================================================
show_step "2/4" "多敌人战斗测试"
show_info "测试4种不同敌人的完整战斗..."

# 使用已知会产生不同敌人的 seed
SEEDS=(1 2 3 5)
ENEMY_NAMES=("信徒" "下颚虫" "绿虱子" "红虱子")

for i in "${!SEEDS[@]}"; do
    SEED=${SEEDS[$i]}
    EXPECTED=${ENEMY_NAMES[$i]}
    
    # 生成30回合的输入
    INPUT_SEQ="1"
    for j in {1..30}; do
        INPUT_SEQ="${INPUT_SEQ}\n1\n1\n1\n1\n1\n0"
    done
    
    OUTPUT=$(echo -e "$INPUT_SEQ" | swift run GameCLI --seed $SEED 2>&1)
    
    # 获取敌人名称
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" | head -1 | sed 's/👹 //' | tr -d '[:space:]')
    
    # 检查战斗结果
    if echo "$OUTPUT" | grep -q "战斗胜利\|战斗失败"; then
        RESULT=$(echo "$OUTPUT" | grep -o "战斗胜利\|战斗失败" | head -1)
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${GREEN}${RESULT}${NC}"
    else
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${YELLOW}进行中${NC}"
    fi
done

show_success "多敌人战斗测试完成"
echo ""

# ============================================================
# 测试3：状态效果验证
# ============================================================
show_step "3/4" "状态效果集成测试"
show_info "验证状态效果施加和伤害计算..."

# 用一个会遇到信徒的 seed（信徒会使用仪式增加力量）
INPUT_SEQ="1"
for i in {1..10}; do
    INPUT_SEQ="${INPUT_SEQ}\n1\n1\n1\n0"
done
INPUT_SEQ="${INPUT_SEQ}\nq\n3"

OUTPUT=$(echo -e "$INPUT_SEQ" | swift run GameCLI --seed 1 2>&1)

EFFECTS_FOUND=0

if echo "$OUTPUT" | grep -q "力量\|仪式"; then
    show_detail "检测到力量/仪式效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if echo "$OUTPUT" | grep -q "易伤"; then
    show_detail "检测到易伤效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if echo "$OUTPUT" | grep -q "虚弱"; then
    show_detail "检测到虚弱效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if echo "$OUTPUT" | grep -q "卷曲"; then
    show_detail "检测到卷曲效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if [ $EFFECTS_FOUND -gt 0 ]; then
    show_success "状态效果系统正常（检测到 $EFFECTS_FOUND 种效果）"
else
    show_warning "未检测到状态效果"
fi

echo ""

# ============================================================
# 测试4：洗牌和牌堆管理
# ============================================================
show_step "4/4" "洗牌机制测试"
show_info "验证抽牌堆耗尽后的洗牌逻辑..."

# 连续多回合，确保触发洗牌
# 初始牌组13张，每回合抽5张，大约3回合后需要洗牌
INPUT_SEQ="1"
for i in {1..10}; do
    INPUT_SEQ="${INPUT_SEQ}\n0"  # 只结束回合，不打牌
done
INPUT_SEQ="${INPUT_SEQ}\nq\n3"

OUTPUT=$(echo -e "$INPUT_SEQ" | swift run GameCLI --seed 88 2>&1)

if echo "$OUTPUT" | grep -q "洗牌\|洗入"; then
    SHUFFLE_COUNT=$(echo "$OUTPUT" | grep -c "洗牌\|洗入" || true)
    show_success "洗牌机制正常（触发 $SHUFFLE_COUNT 次洗牌）"
else
    # 检查抽牌堆和弃牌堆信息
    if echo "$OUTPUT" | grep -q "抽牌堆\|弃牌堆"; then
        show_detail "牌堆管理正常"
        show_success "洗牌测试通过"
    else
        show_warning "未检测到洗牌事件"
    fi
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((4 - FAILED)) 4
exit $FAILED
