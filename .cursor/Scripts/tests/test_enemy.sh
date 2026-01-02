#!/bin/bash

# ============================================================
# Salu 测试 - 敌人系统测试
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "敌人系统测试"

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

# 敌人随机系统测试
show_step "1/2" "敌人随机系统"
show_info "使用不同 seed 检查敌人多样性..."

ALL_ENEMIES=""

for seed in 1 2 3 4 5 10 20 30 40 50; do
    ENEMY=$(run_with_timeout "1\nq\n3" $seed | grep -o "👹 [^[]*" | head -1 | sed 's/👹 //' | tr -d '[:space:]')
    echo -e "     Seed $seed: ${CYAN}${ENEMY}${NC}"
    ALL_ENEMIES="${ALL_ENEMIES}${ENEMY}\n"
done

UNIQUE_COUNT=$(echo -e "$ALL_ENEMIES" | sort | uniq | grep -v "^$" | wc -l | tr -d ' ')

echo ""
show_detail "发现 ${UNIQUE_COUNT} 种不同敌人"

if [ "$UNIQUE_COUNT" -ge 3 ]; then
    show_success "敌人随机系统正常 (发现 $UNIQUE_COUNT 种敌人)"
else
    show_warning "敌人多样性不足 (仅 $UNIQUE_COUNT 种)"
fi
echo ""

# 敌人意图显示测试
show_step "2/2" "敌人意图显示"

OUTPUT=$(run_with_timeout "1\nq\n3" 1)

if echo "$OUTPUT" | grep -q "意图"; then
    INTENT=$(echo "$OUTPUT" | grep "意图" | head -1)
    show_success "敌人意图显示正常"
    show_detail "${INTENT}"
else
    show_failure "未检测到敌人意图"
    FAILED=$((FAILED + 1))
fi
echo ""

show_result $((2 - FAILED)) 2
exit $FAILED

