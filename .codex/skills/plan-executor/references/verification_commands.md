# 执行阶段常用验证命令（按项目选择）

```bash
# 先优先用项目 README/CI 中的标准命令。
# 下面只是常见示例：根据你的项目类型选择合适的一条或多条。

# SwiftPM
swift test
swift build

# Node
npm test
npm run lint
npm run build

# Python
pytest
ruff check .
mypy .

# Go
go test ./...

# Rust
cargo test
cargo fmt --check
cargo clippy -- -D warnings
```

常用环境变量（可选，用于避免污染真实用户数据/加速测试）：

```bash
# 示例：把 app 的数据目录指向临时目录（如果项目支持）
export APP_DATA_DIR=/tmp/app-dev

# 示例：显式开启测试模式（如果项目支持）
export APP_TEST_MODE=1
```
