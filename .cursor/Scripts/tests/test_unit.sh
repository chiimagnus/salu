#!/bin/bash

# ============================================================
# Salu 测试 - 单元测试（swift test）
# ============================================================
# 目的：验证内部逻辑确实实现（非仅靠 CLI 输出/grep）

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cd "$(get_project_root)"

show_header "单元测试（swift test）"

FAILED=0

show_step "1/1" "运行 swift test"
if swift test 2>&1; then
    show_success "swift test 通过"
else
    show_failure "swift test 失败"
    FAILED=$((FAILED + 1))
fi

echo ""
show_result $((1 - FAILED)) 1
exit $FAILED


