#!/bin/bash

# ============================================================
# Salu 测试 - 战斗后奖励系统测试（P1）
# ============================================================
# 目标：
# - 战斗胜利后出现奖励界面
# - 选择 1 张卡牌后，deck 数量从 13 变为 14
# - 使用 SALU_DATA_DIR 隔离测试数据

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "战斗后奖励系统测试"

GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

TMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true
    pkill -f "GameCLI --seed" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

FAILED=0

export SALU_DATA_DIR="$TMP_DIR"
SAVE_FILE="$TMP_DIR/run_save.json"

show_step "1/2" "跑一场战斗并选择奖励"
show_info "开始冒险 → 起点 → 第一场战斗 → 选择奖励 → 返回主菜单 → 退出"

# 输入策略：
# - 进入冒险：1
# - 选择起点：1（起点节点）
# - 选择第一个节点：1（通常是战斗）
# - 战斗：重复打第 1 张牌并结束回合（足够多轮，确保胜利）
# - 奖励界面：选择 [1]
# - 地图：q 返回主菜单
# - 主菜单（有存档时）：4 退出

INPUT_FILE="$TMP_DIR/input.txt"
{
  printf "1\n"   # 开始冒险
  printf "1\n"   # 选择起点节点
  printf "1\n"   # 选择第一个可选节点（战斗）
  # 战斗输入：30 个回合的操作序列（足够覆盖所有弱敌人）
  for _ in $(seq 1 30); do
    printf "1\n1\n1\n1\n1\n0\n"
  done
  printf "1\n"   # 奖励选择：选第 1 张
  printf "q\n"   # 返回主菜单
  printf "4\n"   # 退出（有存档时）
} > "$INPUT_FILE"

OUTPUT=$("$GAME_BIN" --seed 123 < "$INPUT_FILE" 2>&1 || true)

if echo "$OUTPUT" | grep -q "战斗奖励" 2>/dev/null; then
    show_success "检测到奖励界面"
else
    show_failure "未检测到奖励界面（可能未赢得战斗）"
    FAILED=$((FAILED + 1))
fi

echo ""

show_step "2/2" "验证存档 deck 数量增长"
if [ ! -f "$SAVE_FILE" ]; then
    show_failure "未生成存档文件：run_save.json"
    FAILED=$((FAILED + 1))
else
    DECK_COUNT=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["deck"]))' "$SAVE_FILE" 2>/dev/null || echo "0")
    show_detail "deck 数量：$DECK_COUNT"
    if [ "$DECK_COUNT" -ge 14 ]; then
        show_success "奖励已加入牌组（deck >= 14）"
    else
        show_failure "deck 数量未增长（期望 >= 14）"
        FAILED=$((FAILED + 1))
    fi
fi

echo ""

show_result $((2 - FAILED)) 2
exit $FAILED


