# Salu 执行阶段常用验证命令

```bash
# 全量单测（默认优先）
swift test

# 仅构建（测试太慢时的最低保障）
swift build

# 覆盖率（可选）
swift test --enable-code-coverage
```

常用环境变量（避免污染真实用户数据）：

```bash
export SALU_DATA_DIR=/tmp/salu-dev
export SALU_TEST_MODE=1
```

