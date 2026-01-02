#!/bin/bash

# ============================================================
# Salu 测试 - 编译测试
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "编译测试"

FAILED=0

# Debug 编译
show_step "1/2" "Debug 编译"
if swift build 2>&1; then
    show_success "Debug 编译成功"
else
    show_failure "Debug 编译失败"
    FAILED=$((FAILED + 1))
fi
echo ""

# Release 编译
show_step "2/2" "Release 编译"
if swift build -c release 2>&1; then
    show_success "Release 编译成功"
else
    show_failure "Release 编译失败"
    FAILED=$((FAILED + 1))
fi
echo ""

show_result $((2 - FAILED)) 2
exit $FAILED

