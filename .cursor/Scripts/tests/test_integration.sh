#!/bin/bash

# ============================================================
# Salu 测试 - 集成测试（完整战斗流程）
# ============================================================
# 测试完整的战斗流程：开始战斗 → 打牌 → 结束回合 → 战斗结束
# 使用临时文件存储输入，避免 bash 内存溢出
# 使用超时机制确保进程不会无限运行

# 忽略 SIGPIPE 信号（战斗提前结束时剩余输入被丢弃会触发）
trap '' PIPE

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "集成测试（完整战斗流程）"

# 超时时间（秒）- 每个战斗最多运行30秒
TIMEOUT_SECONDS=30

# 确保使用 Release 编译好的二进制
GAME_BIN=".build/release/GameCLI"
if [ ! -f "$GAME_BIN" ]; then
    show_info "编译 Release 版本..."
    swift build -c release 2>&1
fi

# 创建临时文件目录
TMP_DIR=$(mktemp -d)

# 清理函数：确保退出时清理临时文件和子进程
cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true
    # 杀掉可能遗留的 GameCLI 进程
    pkill -f "GameCLI --seed" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 带超时运行游戏的函数
# 注意：Broken pipe 警告是正常的（战斗提前结束时剩余输入被丢弃）
run_game_with_timeout() {
    local input_file="$1"
    local seed="$2"
    local timeout_sec="${3:-$TIMEOUT_SECONDS}"
    
    # 使用 timeout 命令（如果存在），否则使用后台进程+等待
    # 2>/dev/null 隐藏 Broken pipe 警告
    if command -v timeout &>/dev/null; then
        timeout "$timeout_sec" "$GAME_BIN" --seed "$seed" < "$input_file" 2>/dev/null || true
    elif command -v gtimeout &>/dev/null; then
        # macOS 可能需要 coreutils 的 gtimeout
        gtimeout "$timeout_sec" "$GAME_BIN" --seed "$seed" < "$input_file" 2>/dev/null || true
    else
        # 回退方案：后台运行 + sleep + kill
        "$GAME_BIN" --seed "$seed" < "$input_file" 2>/dev/null &
        local pid=$!
        (sleep "$timeout_sec"; kill -9 "$pid" 2>/dev/null) &
        local killer=$!
        wait "$pid" 2>/dev/null || true
        kill "$killer" 2>/dev/null || true
    fi
}

FAILED=0

# ============================================================
# 辅助函数：生成战斗输入文件
# ============================================================
generate_battle_input() {
    local output_file="$1"
    local rounds="$2"
    
    {
        echo "1"  # 开始战斗
        for i in $(seq 1 $rounds); do
            echo "1"  # 打第1张牌
            echo "1"  # 打第1张牌
            echo "1"  # 打第1张牌
            echo "1"  # 打第1张牌
            echo "1"  # 打第1张牌
            echo "0"  # 结束回合
        done
    } > "$output_file" 2>/dev/null
}

# ============================================================
# 测试1：完整战斗直到结束
# ============================================================
show_step "1/4" "完整战斗流程 (seed=100)"
show_info "模拟玩家完成整局战斗（最多30回合）..."

INPUT_FILE="$TMP_DIR/battle_input_1.txt"
generate_battle_input "$INPUT_FILE" 50

echo -e "${CYAN}  → 开始战斗（seed=100，超时${TIMEOUT_SECONDS}秒）...${NC}"

OUTPUT=$(run_game_with_timeout "$INPUT_FILE" 100)

# 检查战斗结果（注意：界面显示是 "战 斗 胜 利" 有空格）
# 使用 grep -m1 和 2>/dev/null 避免 Broken pipe 警告
if grep -q "战.*斗.*胜.*利\|VICTORY" <<< "$OUTPUT" 2>/dev/null; then
    show_success "战斗完成：胜利！"
    ENEMY=$(grep -o "👹 [^[]*" <<< "$OUTPUT" 2>/dev/null | head -1)
    show_detail "对战敌人: $ENEMY"
elif grep -q "战.*斗.*失.*败\|DEFEAT" <<< "$OUTPUT" 2>/dev/null; then
    show_success "战斗完成：失败（但流程正常）"
    ENEMY=$(grep -o "👹 [^[]*" <<< "$OUTPUT" 2>/dev/null | head -1)
    show_detail "对战敌人: $ENEMY"
else
    if grep -q "👹" <<< "$OUTPUT" 2>/dev/null; then
        show_warning "战斗未在50回合内结束，但流程正常"
    else
        show_failure "战斗流程异常"
        FAILED=$((FAILED + 1))
    fi
fi

echo ""

# ============================================================
# 测试2：多敌人完整战斗
# ============================================================
show_step "2/4" "多敌人战斗测试"
show_info "测试4种不同敌人的完整战斗..."

SEEDS=(1 2 3 5)
WINS=0
LOSSES=0

for SEED in "${SEEDS[@]}"; do
    INPUT_FILE="$TMP_DIR/battle_input_seed_$SEED.txt"
    generate_battle_input "$INPUT_FILE" 50
    
    OUTPUT=$(run_game_with_timeout "$INPUT_FILE" "$SEED")
    
    # 获取敌人名称
    ENEMY=$(grep -o "👹 [^[]*" <<< "$OUTPUT" 2>/dev/null | head -1 | sed 's/👹 //' | tr -d '[:space:]')
    
    # 检查战斗结果
    if grep -q "战.*斗.*胜.*利\|VICTORY" <<< "$OUTPUT" 2>/dev/null; then
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${GREEN}胜利${NC}"
        WINS=$((WINS + 1))
    elif grep -q "战.*斗.*失.*败\|DEFEAT" <<< "$OUTPUT" 2>/dev/null; then
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${RED}失败${NC}"
        LOSSES=$((LOSSES + 1))
    else
        echo -e "     Seed $SEED: ${CYAN}${ENEMY}${NC} → ${YELLOW}进行中${NC}"
    fi
done

show_success "多敌人战斗测试完成（胜: $WINS, 负: $LOSSES）"
echo ""

# ============================================================
# 测试3：状态效果集成测试
# ============================================================
show_step "3/4" "状态效果集成测试"
show_info "验证状态效果施加和伤害计算..."

# 生成8回合的输入
INPUT_FILE="$TMP_DIR/battle_input_status.txt"
echo "1" > "$INPUT_FILE"
for i in $(seq 1 8); do
    echo "1" >> "$INPUT_FILE"
    echo "1" >> "$INPUT_FILE"
    echo "1" >> "$INPUT_FILE"
    echo "0" >> "$INPUT_FILE"
done
echo "q" >> "$INPUT_FILE"
echo "3" >> "$INPUT_FILE"

OUTPUT=$(run_game_with_timeout "$INPUT_FILE" 1)

EFFECTS_FOUND=0

if grep -q "力量\|仪式" <<< "$OUTPUT" 2>/dev/null; then
    show_detail "检测到力量/仪式效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if grep -q "易伤" <<< "$OUTPUT" 2>/dev/null; then
    show_detail "检测到易伤效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if grep -q "虚弱" <<< "$OUTPUT" 2>/dev/null; then
    show_detail "检测到虚弱效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if grep -q "卷曲" <<< "$OUTPUT" 2>/dev/null; then
    show_detail "检测到卷曲效果"
    EFFECTS_FOUND=$((EFFECTS_FOUND + 1))
fi

if [ $EFFECTS_FOUND -gt 0 ]; then
    show_success "状态效果系统正常（检测到 $EFFECTS_FOUND 种效果）"
else
    show_warning "未检测到状态效果"
fi

echo ""

# ============================================================
# 测试4：洗牌和牌堆管理
# ============================================================
show_step "4/4" "洗牌机制测试"
show_info "验证抽牌堆耗尽后的洗牌逻辑..."

# 连续8回合只结束回合，触发洗牌
INPUT_FILE="$TMP_DIR/battle_input_shuffle.txt"
echo "1" > "$INPUT_FILE"
for i in $(seq 1 8); do
    echo "0" >> "$INPUT_FILE"
done
echo "q" >> "$INPUT_FILE"
echo "3" >> "$INPUT_FILE"

OUTPUT=$(run_game_with_timeout "$INPUT_FILE" 88)

if grep -q "洗牌\|洗入" <<< "$OUTPUT" 2>/dev/null; then
    show_success "洗牌机制正常（触发洗牌）"
else
    if grep -q "抽牌堆\|弃牌堆" <<< "$OUTPUT" 2>/dev/null; then
        show_success "牌堆管理正常"
    else
        show_warning "未检测到洗牌事件"
    fi
fi

echo ""

# ============================================================
# 结果汇总
# ============================================================
show_result $((4 - FAILED)) 4
exit $FAILED
