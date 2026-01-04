#!/bin/bash

# ============================================================
# Salu 测试 - 敌人系统测试（优化版）
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "敌人系统测试"

GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

# 使用临时数据目录，避免污染真实用户数据
TMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true
    pkill -f "GameCLI --seed" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
export SALU_DATA_DIR="$TMP_DIR"

FAILED=0

# 敌人随机系统测试（减少到5个seed）
# 注意：现在需要进入冒险模式 → 选择起点 → 选择第一个节点 才能看到敌人
show_step "1/2" "敌人随机系统"
show_info "检查敌人多样性..."

ALL_ENEMIES=""

for seed in 1 2 3 5 10; do
    # 开始冒险 → 选择起点 → 选择第一个战斗节点 → 退出战斗 → 退出冒险 → 退出游戏
    OUTPUT=$(echo -e "1\n1\n1\nq\nq\n3" | "$GAME_BIN" --seed $seed 2>&1 || true)
    ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" 2>/dev/null | head -1 | sed 's/👹 //' | tr -d '[:space:]' || echo "未知")
    echo -e "     Seed $seed: ${CYAN}${ENEMY}${NC}"
    ALL_ENEMIES="${ALL_ENEMIES}${ENEMY}\n"
done

UNIQUE_COUNT=$(echo -e "$ALL_ENEMIES" | sort | uniq | grep -v "^$" | grep -v "未知" | wc -l | tr -d ' ')

echo ""
show_detail "发现 ${UNIQUE_COUNT} 种不同敌人"

if [ "$UNIQUE_COUNT" -ge 2 ]; then
    show_success "敌人随机系统正常 ($UNIQUE_COUNT 种)"
else
    show_warning "敌人多样性不足 ($UNIQUE_COUNT 种)"
fi
echo ""

# 敌人意图显示测试
show_step "2/2" "敌人意图显示"

# 开始冒险 → 选择起点 → 选择第一个战斗节点
OUTPUT=$(echo -e "1\n1\n1\nq\nq\n3" | "$GAME_BIN" --seed 1 2>&1 || true)

if echo "$OUTPUT" | grep -q "意图" 2>/dev/null; then
    INTENT=$(echo "$OUTPUT" | grep "意图" 2>/dev/null | head -1)
    show_success "敌人意图显示正常"
    show_detail "${INTENT}"
else
    show_failure "未检测到敌人意图"
    FAILED=$((FAILED + 1))
fi
echo ""

show_result $((2 - FAILED)) 2
exit $FAILED
