#!/bin/bash

# ============================================================
# Salu 测试 - 启动测试
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "启动测试"

# 超时时间
TIMEOUT_SECONDS=10

# 使用编译好的二进制
GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

# 清理函数
cleanup() {
    pkill -f "GameCLI --seed" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 带超时运行
run_with_timeout() {
    local input="$1"
    local seed="$2"
    
    if command -v timeout &>/dev/null; then
        echo -e "$input" | timeout "$TIMEOUT_SECONDS" "$GAME_BIN" --seed "$seed" 2>&1 || true
    elif command -v gtimeout &>/dev/null; then
        echo -e "$input" | gtimeout "$TIMEOUT_SECONDS" "$GAME_BIN" --seed "$seed" 2>&1 || true
    else
        echo -e "$input" | "$GAME_BIN" --seed "$seed" 2>&1 &
        local pid=$!
        (sleep "$TIMEOUT_SECONDS"; kill -9 "$pid" 2>/dev/null) &
        local killer=$!
        wait "$pid" 2>/dev/null || true
        kill "$killer" 2>/dev/null || true
    fi
}

FAILED=0

# 快速启动测试
show_step "1/2" "主菜单启动"
show_info "启动游戏并立即退出..."

OUTPUT=$(run_with_timeout "3" 1 | head -30)

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

OUTPUT=$(run_with_timeout "1\nq\n3" 1)

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

