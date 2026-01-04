#!/bin/bash

# ============================================================
# Salu 测试 - 存档系统测试（P7）
# ============================================================
# 测试流程：
# 1) 开始新冒险 → 选择起点节点（自动完成）→ 退出回到主菜单 → 退出游戏
# 2) 再次启动 → 菜单出现“继续上次冒险” → 继续 → 退出回主菜单 → 退出游戏
# 3) 全程使用 SALU_DATA_DIR 指向临时目录，避免污染真实用户数据

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "存档系统测试"

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

# ============================================================
# 测试 1：创建存档
# ============================================================
show_step "1/2" "创建存档（起点节点完成后自动保存）"
show_info "开始新冒险 → 选择起点 → 退出..."

# 主菜单：无存档时 [1] 开始冒险
# 地图：选择第 1 个可进入节点（起点）
# 地图：输入 q 返回主菜单
# 主菜单：退出
OUTPUT=$(
  echo -e "1\n1\nq\n3\n" | "$GAME_BIN" --seed 123 2>&1 || true
)

if [ -f "$SAVE_FILE" ]; then
    show_success "存档文件已生成：run_save.json"
else
    show_failure "未生成存档文件"
    FAILED=$((FAILED + 1))
fi

echo ""

# ============================================================
# 测试 2：加载存档（继续冒险）
# ============================================================
show_step "2/2" "加载存档（继续上次冒险）"
show_info "再次启动 → 继续上次冒险 → 退出..."

# 主菜单：有存档时 [1] 继续上次冒险，[4] 退出
# 继续后进入地图：q 返回主菜单
# 主菜单：退出
OUTPUT=$(
  echo -e "1\nq\n4\n" | "$GAME_BIN" --seed 999 2>&1 || true
)

if echo "$OUTPUT" | grep -q "存档加载成功" 2>/dev/null; then
    show_success "存档加载成功提示正常"
else
    show_failure "未检测到“存档加载成功”提示"
    FAILED=$((FAILED + 1))
fi

echo ""

show_result $((2 - FAILED)) 2
exit $FAILED


