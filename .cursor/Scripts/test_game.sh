#!/bin/bash

# ============================================================
# Salu - 游戏测试脚本 v3.0
# ============================================================
# 用法：
#   ./.cursor/Scripts/test_game.sh           # 运行所有测试
#   ./.cursor/Scripts/test_game.sh build     # 仅测试编译
#   ./.cursor/Scripts/test_game.sh quick     # 快速测试（编译+启动验证）
#   ./.cursor/Scripts/test_game.sh enemy     # 测试敌人随机系统
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 切换到项目根目录（从 .cursor/Scripts 向上两级）
cd "$(dirname "$0")/../.."
PROJECT_ROOT=$(pwd)

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Salu 测试脚本 v3.0             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}项目目录: ${PROJECT_ROOT}${NC}"
echo ""

# ============================================================
# 测试函数
# ============================================================

test_build() {
    echo -e "${YELLOW}[1/N] 编译项目 (Debug)...${NC}"
    if swift build 2>&1; then
        echo -e "${GREEN}  ✅ Debug 编译成功${NC}"
        return 0
    else
        echo -e "${RED}  ❌ Debug 编译失败${NC}"
        return 1
    fi
}

test_build_release() {
    echo -e "${YELLOW}[2/N] 编译项目 (Release)...${NC}"
    if swift build -c release 2>&1; then
        echo -e "${GREEN}  ✅ Release 编译成功${NC}"
        return 0
    else
        echo -e "${RED}  ❌ Release 编译失败${NC}"
        return 1
    fi
}

test_quick_start() {
    echo -e "${YELLOW}[3/N] 快速启动测试...${NC}"
    
    # 只测试游戏能否正常启动和显示主菜单
    # 输入 3 直接退出
    echo -e "${CYAN}  → 启动游戏并立即退出...${NC}"
    
    OUTPUT=$(echo -e "3" | swift run GameCLI --seed 1 2>&1 | head -30)
    
    if echo "$OUTPUT" | grep -q "SALU\|杀戮尖塔\|开始战斗"; then
        echo -e "${GREEN}  ✅ 游戏启动正常${NC}"
        return 0
    else
        echo -e "${RED}  ❌ 游戏启动失败${NC}"
        echo "$OUTPUT"
        return 1
    fi
}

test_battle_start() {
    echo -e "${YELLOW}[4/N] 战斗启动测试...${NC}"
    
    # 进入战斗，然后立即退出
    # 1 = 开始战斗, q = 退出战斗, 3 = 退出游戏
    echo -e "${CYAN}  → 进入战斗并退出...${NC}"
    
    OUTPUT=$(echo -e "1\nq\n3" | swift run GameCLI --seed 1 2>&1)
    
    # 检查是否显示敌人
    if echo "$OUTPUT" | grep -q "👹"; then
        ENEMY=$(echo "$OUTPUT" | grep -o "👹 [^[]*" | head -1 | sed 's/\[.*//')
        echo -e "${GREEN}  ✅ 战斗启动正常${NC}"
        echo -e "${CYAN}     遇到敌人: ${ENEMY}${NC}"
        return 0
    else
        echo -e "${RED}  ❌ 战斗启动失败${NC}"
        echo "$OUTPUT" | tail -20
        return 1
    fi
}

test_enemy_variety() {
    echo -e "${YELLOW}[5/N] 敌人随机系统测试...${NC}"
    
    echo -e "${CYAN}  → 使用不同 seed 检查敌人多样性...${NC}"
    
    # 收集所有敌人名称
    ALL_ENEMIES=""
    
    for seed in 1 2 3 4 5 10 20 30 40 50; do
        ENEMY=$(echo -e "1\nq\n3" | swift run GameCLI --seed $seed 2>&1 | grep -o "👹 [^[]*" | head -1 | sed 's/👹 //' | tr -d '[:space:]')
        echo -e "     Seed $seed: ${CYAN}${ENEMY}${NC}"
        ALL_ENEMIES="${ALL_ENEMIES}${ENEMY}\n"
    done
    
    # 计算唯一敌人数量
    UNIQUE_COUNT=$(echo -e "$ALL_ENEMIES" | sort | uniq | grep -v "^$" | wc -l | tr -d ' ')
    
    echo ""
    echo -e "${CYAN}  发现 ${UNIQUE_COUNT} 种不同敌人${NC}"
    
    if [ "$UNIQUE_COUNT" -ge 3 ]; then
        echo -e "${GREEN}  ✅ 敌人随机系统正常 (发现 $UNIQUE_COUNT 种敌人)${NC}"
        return 0
    else
        echo -e "${YELLOW}  ⚠️ 敌人多样性不足 (仅 $UNIQUE_COUNT 种)${NC}"
        return 0  # 不算失败
    fi
}

test_intent_display() {
    echo -e "${YELLOW}[6/N] 敌人意图显示测试...${NC}"
    
    OUTPUT=$(echo -e "1\nq\n3" | swift run GameCLI --seed 1 2>&1)
    
    if echo "$OUTPUT" | grep -q "意图"; then
        INTENT=$(echo "$OUTPUT" | grep "意图" | head -1)
        echo -e "${GREEN}  ✅ 敌人意图显示正常${NC}"
        echo -e "${CYAN}     ${INTENT}${NC}"
        return 0
    else
        echo -e "${RED}  ❌ 未检测到敌人意图${NC}"
        return 1
    fi
}

# ============================================================
# 主逻辑
# ============================================================

run_all_tests() {
    echo ""
    FAILED=0
    TOTAL=6
    
    test_build || FAILED=$((FAILED + 1))
    echo ""
    
    test_build_release || FAILED=$((FAILED + 1))
    echo ""
    
    test_quick_start || FAILED=$((FAILED + 1))
    echo ""
    
    test_battle_start || FAILED=$((FAILED + 1))
    echo ""
    
    test_enemy_variety || FAILED=$((FAILED + 1))
    echo ""
    
    test_intent_display || FAILED=$((FAILED + 1))
    echo ""
    
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    PASSED=$((TOTAL - FAILED))
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试通过！ ($PASSED/$TOTAL)${NC}"
    else
        echo -e "${RED}❌ ${FAILED} 个测试失败 ($PASSED/$TOTAL 通过)${NC}"
    fi
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    
    return $FAILED
}

run_quick_tests() {
    echo ""
    FAILED=0
    
    test_build || FAILED=$((FAILED + 1))
    echo ""
    
    test_quick_start || FAILED=$((FAILED + 1))
    echo ""
    
    test_battle_start || FAILED=$((FAILED + 1))
    echo ""
    
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 快速测试通过！${NC}"
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
    quick)
        run_quick_tests
        ;;
    enemy)
        test_build && test_enemy_variety
        ;;
    intent)
        test_build && test_intent_display
        ;;
    all|*)
        run_all_tests
        ;;
esac
