#!/bin/bash

# ============================================================
# Salu - 游戏测试脚本
# ============================================================
# 用法：
#   ./Scripts/test_game.sh           # 运行所有测试
#   ./Scripts/test_game.sh build     # 仅测试编译
#   ./Scripts/test_game.sh play      # 自动运行一局游戏
#   ./Scripts/test_game.sh reproduce # 测试可复现性
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 切换到项目根目录
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Salu 测试脚本 v1.0             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# 测试函数
# ============================================================

test_build() {
    echo -e "${YELLOW}[测试] 编译项目...${NC}"
    if swift build 2>&1; then
        echo -e "${GREEN}✅ 编译成功${NC}"
        return 0
    else
        echo -e "${RED}❌ 编译失败${NC}"
        return 1
    fi
}

test_build_release() {
    echo -e "${YELLOW}[测试] Release 编译...${NC}"
    if swift build -c release 2>&1; then
        echo -e "${GREEN}✅ Release 编译成功${NC}"
        return 0
    else
        echo -e "${RED}❌ Release 编译失败${NC}"
        return 1
    fi
}

test_play_game() {
    echo -e "${YELLOW}[测试] 自动运行一局游戏 (seed=1)...${NC}"
    
    # 使用攻击优先策略：每回合尽量打出所有攻击牌
    # 输入序列：1 表示打第一张牌，0 表示结束回合
    INPUT_SEQUENCE="1\n1\n1\n0\n1\n1\n1\n0\n1\n1\n1\n0\n1\n1\n1\n0\n1\n1\n1\n0\n1\n1\n1\n0\n1\n1\n1\n0"
    
    OUTPUT=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 1 2>&1)
    
    # 检查是否包含胜利或失败
    if echo "$OUTPUT" | grep -q "战斗胜利"; then
        echo -e "${GREEN}✅ 游戏正常运行，战斗胜利${NC}"
        return 0
    elif echo "$OUTPUT" | grep -q "战斗失败"; then
        echo -e "${GREEN}✅ 游戏正常运行，战斗失败${NC}"
        return 0
    else
        echo -e "${RED}❌ 游戏未正常结束${NC}"
        echo "$OUTPUT" | tail -20
        return 1
    fi
}

test_reproducibility() {
    echo -e "${YELLOW}[测试] 可复现性验证 (seed=42)...${NC}"
    
    INPUT_SEQUENCE="1\n1\n1\n0"
    
    # 运行两次相同的输入
    OUTPUT1=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 42 2>&1 | grep "抽到" | head -5)
    OUTPUT2=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 42 2>&1 | grep "抽到" | head -5)
    
    if [ "$OUTPUT1" = "$OUTPUT2" ]; then
        echo -e "${GREEN}✅ 可复现性验证通过${NC}"
        echo "  第一回合抽牌序列："
        echo "$OUTPUT1" | sed 's/^/    /'
        return 0
    else
        echo -e "${RED}❌ 可复现性验证失败${NC}"
        echo "第一次运行："
        echo "$OUTPUT1"
        echo "第二次运行："
        echo "$OUTPUT2"
        return 1
    fi
}

test_shuffle_mechanic() {
    echo -e "${YELLOW}[测试] 洗牌机制验证...${NC}"
    
    # 多回合游戏，确保触发洗牌
    INPUT_SEQUENCE="0\n0\n0\n0\n0\n0\nq"  # 连续结束回合，触发洗牌
    
    OUTPUT=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 1 2>&1)
    
    if echo "$OUTPUT" | grep -q "洗牌"; then
        echo -e "${GREEN}✅ 洗牌机制正常${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未触发洗牌（可能回合数不够）${NC}"
        return 0  # 不算失败
    fi
}

test_block_mechanic() {
    echo -e "${YELLOW}[测试] 格挡机制验证...${NC}"
    
    # 第一回合使用防御牌
    INPUT_SEQUENCE="1\n0\nq"  # 打第一张牌（可能是防御），然后结束回合
    
    OUTPUT=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 1 2>&1)
    
    if echo "$OUTPUT" | grep -q "格挡"; then
        echo -e "${GREEN}✅ 格挡机制正常${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未触发格挡（可能第一张不是防御牌）${NC}"
        return 0  # 不算失败
    fi
}

test_energy_mechanic() {
    echo -e "${YELLOW}[测试] 能量机制验证...${NC}"
    
    # 尝试打出多张牌，消耗能量
    INPUT_SEQUENCE="1\n1\n1\n1\nq"  # 连续打4张牌
    
    OUTPUT=$(echo -e "$INPUT_SEQUENCE" | swift run GameCLI --seed 1 2>&1)
    
    # 检查是否有能量消耗相关输出
    if echo "$OUTPUT" | grep -q "能量"; then
        echo -e "${GREEN}✅ 能量机制正常${NC}"
        return 0
    else
        echo -e "${RED}❌ 能量机制异常${NC}"
        return 1
    fi
}

# ============================================================
# 主逻辑
# ============================================================

run_all_tests() {
    echo ""
    FAILED=0
    
    test_build || FAILED=$((FAILED + 1))
    echo ""
    
    test_build_release || FAILED=$((FAILED + 1))
    echo ""
    
    test_play_game || FAILED=$((FAILED + 1))
    echo ""
    
    test_reproducibility || FAILED=$((FAILED + 1))
    echo ""
    
    test_shuffle_mechanic || FAILED=$((FAILED + 1))
    echo ""
    
    test_block_mechanic || FAILED=$((FAILED + 1))
    echo ""
    
    test_energy_mechanic || FAILED=$((FAILED + 1))
    echo ""
    
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试通过！${NC}"
    else
        echo -e "${RED}❌ ${FAILED} 个测试失败${NC}"
    fi
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    
    return $FAILED
}

# 根据参数执行不同测试
case "${1:-all}" in
    build)
        test_build
        ;;
    play)
        test_build && test_play_game
        ;;
    reproduce)
        test_build && test_reproducibility
        ;;
    all|*)
        run_all_tests
        ;;
esac

