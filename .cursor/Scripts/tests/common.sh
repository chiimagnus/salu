#!/bin/bash

# ============================================================
# Salu 测试脚本 - 公共函数库
# ============================================================

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# 切换到项目根目录
get_project_root() {
    cd "$(dirname "$0")/../../.."
    pwd
}

# 显示测试标题
show_header() {
    local title="$1"
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ${title}${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""
}

# 显示测试步骤
show_step() {
    local step="$1"
    local desc="$2"
    echo -e "${YELLOW}[${step}] ${desc}...${NC}"
}

# 显示成功
show_success() {
    local msg="$1"
    echo -e "${GREEN}  ✅ ${msg}${NC}"
}

# 显示失败
show_failure() {
    local msg="$1"
    echo -e "${RED}  ❌ ${msg}${NC}"
}

# 显示警告
show_warning() {
    local msg="$1"
    echo -e "${YELLOW}  ⚠️ ${msg}${NC}"
}

# 显示信息
show_info() {
    local msg="$1"
    echo -e "${CYAN}  → ${msg}${NC}"
}

# 显示详情
show_detail() {
    local msg="$1"
    echo -e "${CYAN}     ${msg}${NC}"
}

# 显示测试结果
show_result() {
    local passed=$1
    local total=$2
    local failed=$((total - passed))
    
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试通过！ ($passed/$total)${NC}"
    else
        echo -e "${RED}❌ ${failed} 个测试失败 ($passed/$total 通过)${NC}"
    fi
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    
    return $failed
}

