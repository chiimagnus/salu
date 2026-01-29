# SaluAVP ViewModels

本目录用于存放 `SaluAVP` 专用的 ViewModels / Session（与 `GameCore` 对接的纯状态层）。

约束：

- 允许依赖 `GameCore`
- 避免依赖 `RealityKit`（让状态层更容易测试/复用）

