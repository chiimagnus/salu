#!/bin/bash

# ============================================================
# Salu 测试 - 启动测试
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "启动测试"

FAILED=0

# 快速启动测试
show_step "1/2" "主菜单启动"
show_info "启动游戏并立即退出..."

OUTPUT=$(echo -e "3" | swift run GameCLI --seed 1 2>&1 | head -30)

if echo "$OUTPUT" | grep -q "SALU\|杀戮尖塔\|开始战斗"; then
    show_success "主菜单启动正常"
else
    show_failure "主菜单启动失败"
    FAILED=$((FAILED + 1))
fi
echo ""

# 战斗启动测试
show_step "2/2" "战斗界面启动"
show_info "进入战斗并退出..."

OUTPUT=$(echo -e "1\nq\n3" | swift run GameCLI --seed 1 2>&1)

if echo "$OUTPUT" | grep -q "👹"; then
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" | head -1 | sed 's/\[.*//')
    show_success "战斗界面启动正常"
    show_detail "遇到敌人: ${ENEMY}"
else
    show_failure "战斗界面启动失败"
    FAILED=$((FAILED + 1))
fi
echo ""

show_result $((2 - FAILED)) 2
exit $FAILED

