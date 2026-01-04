#!/bin/bash

# ============================================================
# Salu - 游戏测试入口 v3.0
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# 确保测试脚本可执行
chmod +x "$TESTS_DIR"/*.sh 2>/dev/null || true

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Salu 测试脚本 v4.0             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo "用法："
    echo "  $0 [command]"
    echo ""
    echo "命令："
    echo "  all         运行所有测试 (默认)"
    echo "  build       编译测试"
    echo "  startup     启动测试"
    echo "  enemy       敌人系统测试"
    echo "  relic       遗物系统测试"
    echo "  map         地图系统测试"
    echo "  save        存档系统测试"
    echo "  reward      战斗后奖励系统测试"
    echo "  unit        单元测试（swift test）"
    echo "  integration 集成测试（完整冒险流程）"
    echo "  quick       快速测试 (编译+启动)"
    echo ""
}

run_test() {
    local test_name="$1"
    local test_script="$TESTS_DIR/test_${test_name}.sh"
    
    if [ -f "$test_script" ]; then
        bash "$test_script"
        return $?
    else
        echo -e "${RED}错误: 未找到测试脚本 $test_script${NC}"
        return 1
    fi
}

run_all_tests() {
    local FAILED=0
    local TOTAL=0
    
    for test_script in "$TESTS_DIR"/test_*.sh; do
        if [ -f "$test_script" ]; then
            TOTAL=$((TOTAL + 1))
            echo ""
            if bash "$test_script"; then
                : # 成功
            else
                FAILED=$((FAILED + 1))
            fi
            echo ""
        fi
    done
    
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo -e "${BLUE}          总体测试结果                ${NC}"
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    
    local PASSED=$((TOTAL - FAILED))
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试套件通过！ ($PASSED/$TOTAL)${NC}"
    else
        echo -e "${RED}❌ ${FAILED} 个测试套件失败 ($PASSED/$TOTAL 通过)${NC}"
    fi
    
    return $FAILED
}

run_quick_tests() {
    local FAILED=0
    
    echo ""
    if ! run_test "build"; then
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
    if ! run_test "startup"; then
        FAILED=$((FAILED + 1))
    fi
    
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

# 主逻辑
case "${1:-all}" in
    build)
        run_test "build"
        ;;
    startup)
        run_test "startup"
        ;;
    enemy)
        run_test "enemy"
        ;;
    relic)
        run_test "relic"
        ;;
    map)
        run_test "map"
        ;;
    save)
        run_test "save"
        ;;
    reward)
        run_test "reward"
        ;;
    unit)
        run_test "unit"
        ;;
    integration)
        run_test "integration"
        ;;
    quick)
        run_quick_tests
        ;;
    all)
        run_all_tests
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        show_usage
        exit 1
        ;;
esac
