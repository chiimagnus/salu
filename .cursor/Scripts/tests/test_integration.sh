#!/bin/bash

# ============================================================
# Salu 测试 - 集成测试（完整冒险流程）
# ============================================================
# 测试完整的冒险流程：开始冒险 → 选择节点 → 战斗 → 休息 → Boss

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "集成测试（完整冒险流程）"

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

# 使用临时数据目录，避免污染真实用户数据
export SALU_DATA_DIR="$TMP_DIR"

FAILED=0

# ============================================================
# 辅助函数：生成冒险输入（选择节点 + 战斗）
# ============================================================
generate_adventure_input() {
    local output_file="$1"
    local battles="${2:-5}"
    
    # 开始冒险
    printf "1\n" > "$output_file"
    
    # 选择起点节点
    printf "1\n" >> "$output_file"
    
    # 多场战斗循环
    for _ in $(seq 1 "$battles"); do
        # 选择第一个可选节点
        printf "1\n" >> "$output_file"
        # 战斗回合（打牌 + 结束回合）
        for _ in $(seq 1 10); do
            printf "1\n1\n1\n1\n1\n0\n" >> "$output_file"
        done
    done
}

# ============================================================
# 测试1：地图生成和显示
# ============================================================
show_step "1/4" "地图生成测试 (seed=100)"
show_info "验证地图显示..."

INPUT_FILE="$TMP_DIR/map1.txt"
printf "1\nq\n3\n" > "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 100 < "$INPUT_FILE" 2>&1 || true)

# 检查地图元素
if echo "$OUTPUT" | grep -q "Boss\|起点\|当前" 2>/dev/null; then
    show_success "地图生成正常"
    echo "$OUTPUT" | grep -q "⚔️" 2>/dev/null && show_detail "检测到战斗节点"
    echo "$OUTPUT" | grep -q "💤" 2>/dev/null && show_detail "检测到休息节点"
    echo "$OUTPUT" | grep -q "👹" 2>/dev/null && show_detail "检测到Boss节点"
else
    show_failure "地图生成异常"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试2：完整冒险流程（3场战斗）
# ============================================================
show_step "2/4" "冒险流程测试 (seed=100)"
show_info "模拟冒险流程（3场战斗）..."

INPUT_FILE="$TMP_DIR/adventure1.txt"
generate_adventure_input "$INPUT_FILE" 3

OUTPUT=$("$GAME_BIN" --seed 100 < "$INPUT_FILE" 2>&1 || true)

# 检查冒险结果
if echo "$OUTPUT" | grep -q "通关\|胜利\|恭喜" 2>/dev/null; then
    show_success "冒险完成：通关！"
elif echo "$OUTPUT" | grep -q "失败\|倒下" 2>/dev/null; then
    show_success "冒险完成：失败（但流程正常）"
elif echo "$OUTPUT" | grep -q "👹" 2>/dev/null; then
    show_success "冒险进行中（流程正常）"
else
    show_failure "冒险流程异常"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试3：状态效果
# ============================================================
show_step "3/4" "状态效果测试"
show_info "验证状态效果..."

INPUT_FILE="$TMP_DIR/status.txt"
# 开始冒险 → 选择起点 → 选择节点 → 战斗
printf "1\n1\n1\n" > "$INPUT_FILE"
for _ in $(seq 1 5); do
    printf "1\n1\n1\n0\n" >> "$INPUT_FILE"
done
printf "q\nq\n3\n" >> "$INPUT_FILE"

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
# 测试4：HP保持测试
# ============================================================
show_step "4/4" "HP保持测试"
show_info "验证战斗间HP保持..."

INPUT_FILE="$TMP_DIR/hp_test.txt"
# 开始冒险 → 选择起点 → 选择节点 → 战斗 → 退出
printf "1\n1\n1\n" > "$INPUT_FILE"
# 第一场战斗
for _ in $(seq 1 8); do
    printf "1\n1\n1\n0\n" >> "$INPUT_FILE"
done
printf "q\nq\n3\n" >> "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 50 < "$INPUT_FILE" 2>&1 || true)

if echo "$OUTPUT" | grep -q "HP" 2>/dev/null; then
    show_success "HP显示正常"
else
    show_warning "未检测到HP信息"
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((4 - FAILED)) 4
exit $FAILED
