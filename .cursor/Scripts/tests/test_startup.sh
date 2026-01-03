#!/bin/bash

# ============================================================
# Salu 测试 - 启动测试（优化版）
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "启动测试"

GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

FAILED=0

# 快速启动测试
show_step "1/3" "主菜单启动"
show_info "启动并退出..."

OUTPUT=$(echo -e "3" | "$GAME_BIN" --seed 1 2>&1 || true)

if echo "$OUTPUT" | grep -q "SALU\|杀戮尖塔\|开始冒险" 2>/dev/null; then
    show_success "主菜单启动正常"
else
    show_failure "主菜单启动失败"
    FAILED=$((FAILED + 1))
fi
echo ""

# 地图启动测试
show_step "2/3" "冒险地图启动"
show_info "进入冒险模式并退出..."

OUTPUT=$(echo -e "1\nq\n3" | "$GAME_BIN" --seed 1 2>&1 || true)

if echo "$OUTPUT" | grep -q "地图\|当前\|起点\|Boss" 2>/dev/null; then
    show_success "冒险地图启动正常"
else
    show_failure "冒险地图启动失败"
    FAILED=$((FAILED + 1))
fi
echo ""

# 战斗启动测试
show_step "3/3" "战斗界面启动"
show_info "选择节点进入战斗并退出..."

OUTPUT=$(echo -e "1\n1\nq\nq\n3" | "$GAME_BIN" --seed 1 2>&1 || true)

if echo "$OUTPUT" | grep -q "👹" 2>/dev/null; then
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" 2>/dev/null | head -1 | sed 's/\[.*//' || echo "未知")
    show_success "战斗界面启动正常"
    show_detail "遇到敌人: ${ENEMY}"
else
    show_failure "战斗界面启动失败"
    FAILED=$((FAILED + 1))
fi
echo ""

show_result $((3 - FAILED)) 3
exit $FAILED
