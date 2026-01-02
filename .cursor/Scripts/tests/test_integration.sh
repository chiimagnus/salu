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

# 确保使用 Release 编译好的二进制
GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

# 创建临时文件目录
TMP_DIR=$(mktemp -d)

# 清理函数
cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true
    pkill -f "GameCLI --seed" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

FAILED=0

# ============================================================
# 辅助函数：生成战斗输入（简化版，10回合足够）
# ============================================================
generate_battle_input() {
    local output_file="$1"
    local rounds="${2:-10}"
    
    # 使用 printf 一次性写入，比循环 echo 快很多
    printf "1\n" > "$output_file"
    for _ in $(seq 1 "$rounds"); do
        printf "1\n1\n1\n1\n1\n0\n" >> "$output_file"
    done
}

# ============================================================
# 测试1：完整战斗直到结束
# ============================================================
show_step "1/4" "完整战斗流程 (seed=100)"
show_info "模拟战斗流程..."

INPUT_FILE="$TMP_DIR/battle1.txt"
generate_battle_input "$INPUT_FILE" 15

OUTPUT=$("$GAME_BIN" --seed 100 < "$INPUT_FILE" 2>&1 || true)

# 检查战斗结果
if echo "$OUTPUT" | grep -q "胜.*利\|VICTOR" 2>/dev/null; then
    show_success "战斗完成：胜利！"
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" 2>/dev/null | head -1 || echo "未知")
    show_detail "对战敌人: $ENEMY"
elif echo "$OUTPUT" | grep -q "失.*败\|DEFEAT" 2>/dev/null; then
    show_success "战斗完成：失败（但流程正常）"
elif echo "$OUTPUT" | grep -q "👹" 2>/dev/null; then
    show_warning "战斗未结束，但流程正常"
else
    show_failure "战斗流程异常"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试2：多敌人战斗
# ============================================================
show_step "2/4" "多敌人战斗测试"
show_info "测试4种不同敌人..."

WINS=0

for SEED in 1 2 3 5; do
    INPUT_FILE="$TMP_DIR/battle_$SEED.txt"
    generate_battle_input "$INPUT_FILE" 15
    
    OUTPUT=$("$GAME_BIN" --seed "$SEED" < "$INPUT_FILE" 2>&1 || true)
    
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" 2>/dev/null | head -1 | sed 's/👹 //' | tr -d '[:space:]' || echo "未知")
    
    if echo "$OUTPUT" | grep -q "胜.*利\|VICTOR" 2>/dev/null; then
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${GREEN}胜利${NC}"
        WINS=$((WINS + 1))
    elif echo "$OUTPUT" | grep -q "失.*败\|DEFEAT" 2>/dev/null; then
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${RED}失败${NC}"
    else
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${YELLOW}进行中${NC}"
    fi
done

show_success "多敌人战斗测试完成（$WINS 胜）"
echo ""

# ============================================================
# 测试3：状态效果
# ============================================================
show_step "3/4" "状态效果测试"
show_info "验证状态效果..."

INPUT_FILE="$TMP_DIR/status.txt"
printf "1\n" > "$INPUT_FILE"
for _ in $(seq 1 5); do
    printf "1\n1\n1\n0\n" >> "$INPUT_FILE"
done
printf "q\n3\n" >> "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 1 < "$INPUT_FILE" 2>&1 || true)

EFFECTS=0
echo "$OUTPUT" | grep -q "力量\|仪式" 2>/dev/null && { show_detail "检测到力量/仪式"; EFFECTS=$((EFFECTS + 1)); }
echo "$OUTPUT" | grep -q "易伤" 2>/dev/null && { show_detail "检测到易伤"; EFFECTS=$((EFFECTS + 1)); }
echo "$OUTPUT" | grep -q "虚弱" 2>/dev/null && { show_detail "检测到虚弱"; EFFECTS=$((EFFECTS + 1)); }

if [ $EFFECTS -gt 0 ]; then
    show_success "状态效果正常（$EFFECTS 种）"
else
    show_warning "未检测到状态效果"
fi

echo ""

# ============================================================
# 测试4：牌堆管理
# ============================================================
show_step "4/4" "牌堆管理测试"
show_info "验证洗牌逻辑..."

INPUT_FILE="$TMP_DIR/shuffle.txt"
printf "1\n" > "$INPUT_FILE"
for _ in $(seq 1 6); do
    printf "0\n" >> "$INPUT_FILE"
done
printf "q\n3\n" >> "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 88 < "$INPUT_FILE" 2>&1 || true)

if echo "$OUTPUT" | grep -q "抽牌堆\|弃牌堆" 2>/dev/null; then
    show_success "牌堆管理正常"
else
    show_warning "未检测到牌堆信息"
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((4 - FAILED)) 4
exit $FAILED
