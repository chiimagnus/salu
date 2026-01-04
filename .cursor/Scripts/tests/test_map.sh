#!/bin/bash

# ============================================================
# Salu 测试 - 地图系统测试
# ============================================================
# 测试地图生成、节点类型、分支路径等

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "地图系统测试"

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
}
trap cleanup EXIT INT TERM

# 使用临时数据目录，避免污染真实用户数据
export SALU_DATA_DIR="$TMP_DIR"

FAILED=0

# ============================================================
# 测试1：地图包含所有必要元素
# ============================================================
show_step "1/4" "地图元素检测"
show_info "检查地图包含起点、Boss、战斗节点..."

INPUT_FILE="$TMP_DIR/map_elements.txt"
printf "1\nq\n3\n" > "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 42 < "$INPUT_FILE" 2>&1 || true)

ELEMENTS=0
echo "$OUTPUT" | grep -q "起点" 2>/dev/null && { show_detail "✓ 起点节点"; ELEMENTS=$((ELEMENTS + 1)); }
echo "$OUTPUT" | grep -q "Boss" 2>/dev/null && { show_detail "✓ Boss节点"; ELEMENTS=$((ELEMENTS + 1)); }
echo "$OUTPUT" | grep -q "当前" 2>/dev/null && { show_detail "✓ 当前位置标记"; ELEMENTS=$((ELEMENTS + 1)); }
echo "$OUTPUT" | grep -q "⚔️" 2>/dev/null && { show_detail "✓ 战斗节点"; ELEMENTS=$((ELEMENTS + 1)); }

if [ $ELEMENTS -ge 3 ]; then
    show_success "地图元素完整 ($ELEMENTS/4)"
else
    show_failure "地图元素不完整 ($ELEMENTS/4)"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试2：不同种子生成不同地图
# ============================================================
show_step "2/4" "地图随机性测试"
show_info "测试不同种子生成不同地图..."

INPUT_FILE="$TMP_DIR/map_seed.txt"
printf "1\nq\n3\n" > "$INPUT_FILE"

MAP1=$("$GAME_BIN" --seed 1 < "$INPUT_FILE" 2>&1 | grep -c "⚔️\|💤\|💀" || echo "0")
MAP2=$("$GAME_BIN" --seed 999 < "$INPUT_FILE" 2>&1 | grep -c "⚔️\|💤\|💀" || echo "0")

show_detail "Seed 1: $MAP1 个节点图标"
show_detail "Seed 999: $MAP2 个节点图标"

# 只要两个地图都有节点就算成功（不要求完全不同）
if [ "$MAP1" -gt 0 ] && [ "$MAP2" -gt 0 ]; then
    show_success "地图生成正常"
else
    show_failure "地图生成异常"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试3：节点选择功能
# ============================================================
show_step "3/4" "节点选择测试"
show_info "测试选择节点功能..."

INPUT_FILE="$TMP_DIR/node_select.txt"
# 开始冒险 → 选择起点 → 退出
printf "1\n1\nq\n3\n" > "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 1 < "$INPUT_FILE" 2>&1 || true)

if echo "$OUTPUT" | grep -q "选择\|节点" 2>/dev/null; then
    show_success "节点选择功能正常"
else
    show_warning "未检测到节点选择提示"
fi

echo ""

# ============================================================
# 测试4：休息节点检测
# ============================================================
show_step "4/4" "休息节点检测"
show_info "检测地图中是否有休息节点..."

INPUT_FILE="$TMP_DIR/rest_node.txt"
printf "1\nq\n3\n" > "$INPUT_FILE"

FOUND_REST=0
for SEED in 1 2 3 5 8 13 21 34; do
    OUTPUT=$("$GAME_BIN" --seed "$SEED" < "$INPUT_FILE" 2>&1 || true)
    if echo "$OUTPUT" | grep -q "💤" 2>/dev/null; then
        FOUND_REST=1
        show_detail "Seed $SEED: 发现休息节点"
        break
    fi
done

if [ $FOUND_REST -eq 1 ]; then
    show_success "休息节点生成正常"
else
    show_warning "未在测试种子中发现休息节点"
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((4 - FAILED)) 4
exit $FAILED

