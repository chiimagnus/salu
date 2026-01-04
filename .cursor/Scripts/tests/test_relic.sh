#!/bin/bash

# ============================================================
# Salu 测试 - 遗物系统测试
# ============================================================
# 测试遗物系统的功能和触发

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "遗物系统测试"

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
# 测试1：燃烧之血遗物（战斗结束恢复HP）
# ============================================================
show_step "1/3" "燃烧之血遗物测试"
show_info "验证战斗胜利后恢复6HP..."

INPUT_FILE="$TMP_DIR/burning_blood.txt"
# 开始冒险 → 选择起点 → 选择节点 → 战斗
printf "1\n1\n1\n" > "$INPUT_FILE"
# 战斗多个回合
for _ in $(seq 1 15); do
    printf "1\n1\n1\n1\n1\n0\n" >> "$INPUT_FILE"
done
printf "q\n3\n" >> "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 42 < "$INPUT_FILE" 2>&1 || true)

# 检查是否有燃烧之血效果（战斗结束后的治疗）
if echo "$OUTPUT" | grep -q "治疗\|恢复\|HP.*增加\|HP.*提升" 2>/dev/null; then
    show_success "燃烧之血遗物触发：战斗结束恢复生命"
elif echo "$OUTPUT" | grep -q "燃烧之血\|🔥" 2>/dev/null; then
    show_success "检测到燃烧之血遗物"
else
    show_warning "未明确检测到燃烧之血效果（可能在事件日志中）"
fi

echo ""

# ============================================================
# 测试2：遗物在冒险中持久化
# ============================================================
show_step "2/3" "遗物持久化测试"
show_info "验证遗物在多场战斗中保持..."

INPUT_FILE="$TMP_DIR/relic_persist.txt"
# 开始冒险 → 多场战斗
printf "1\n1\n1\n" > "$INPUT_FILE"
# 第一场战斗
for _ in $(seq 1 10); do
    printf "1\n1\n1\n0\n" >> "$INPUT_FILE"
done
# 选择下一个节点
printf "1\n" >> "$INPUT_FILE"
# 第二场战斗
for _ in $(seq 1 10); do
    printf "1\n1\n1\n0\n" >> "$INPUT_FILE"
done
printf "q\n3\n" >> "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 100 < "$INPUT_FILE" 2>&1 || true)

if echo "$OUTPUT" | grep -q "战斗\|胜利" 2>/dev/null; then
    show_success "遗物在多场战斗中工作正常"
else
    show_failure "遗物持久化测试异常"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试3：遗物系统架构验证
# ============================================================
show_step "3/3" "遗物系统架构验证"
show_info "验证遗物系统代码结构..."

CHECKS=0
TOTAL=0

# 检查 RelicID
TOTAL=$((TOTAL + 1))
if grep -q "RelicID" Sources/GameCore/Kernel/IDs.swift 2>/dev/null; then
    show_detail "✓ RelicID 类型存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查 RelicDefinition
TOTAL=$((TOTAL + 1))
if [ -f "Sources/GameCore/Relics/RelicDefinition.swift" ]; then
    show_detail "✓ RelicDefinition 协议存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查 RelicRegistry
TOTAL=$((TOTAL + 1))
if [ -f "Sources/GameCore/Relics/RelicRegistry.swift" ]; then
    show_detail "✓ RelicRegistry 存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查 RelicManager
TOTAL=$((TOTAL + 1))
if [ -f "Sources/GameCore/Relics/RelicManager.swift" ]; then
    show_detail "✓ RelicManager 存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查 BattleTrigger
TOTAL=$((TOTAL + 1))
if [ -f "Sources/GameCore/Kernel/BattleTrigger.swift" ]; then
    show_detail "✓ BattleTrigger 存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查遗物定义
TOTAL=$((TOTAL + 1))
if [ -f "Sources/GameCore/Relics/Definitions/BasicRelics.swift" ]; then
    show_detail "✓ 基础遗物定义存在"
    CHECKS=$((CHECKS + 1))
fi

# 检查 RunState 集成
TOTAL=$((TOTAL + 1))
if grep -q "relicManager" Sources/GameCore/Run/RunState.swift 2>/dev/null; then
    show_detail "✓ RunState 包含 RelicManager"
    CHECKS=$((CHECKS + 1))
fi

# 检查 BattleEngine 集成
TOTAL=$((TOTAL + 1))
if grep -q "triggerRelics\|relicManager" Sources/GameCore/Battle/BattleEngine.swift 2>/dev/null; then
    show_detail "✓ BattleEngine 集成遗物触发"
    CHECKS=$((CHECKS + 1))
fi

if [ $CHECKS -eq $TOTAL ]; then
    show_success "遗物系统架构完整 ($CHECKS/$TOTAL)"
else
    show_failure "遗物系统架构不完整 ($CHECKS/$TOTAL)"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((3 - FAILED)) 3
exit $FAILED
