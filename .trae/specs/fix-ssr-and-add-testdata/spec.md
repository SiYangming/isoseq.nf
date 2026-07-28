# Fix SSR, Add Testdata & Profile Option Spec

## Why
1. 当前在 Next.js 服务端渲染 (SSR) 阶段，组件内使用了客户端的 Tauri API，导致 `Hydration mismatch` 和 `transformCallback` 未定义报错。
2. 用户希望在配置表单中，提供一个“默认加载 testdata”的快捷选项。
3. 用户希望能够选择运行配置（Profile），支持在 `docker` 和 `conda` 之间切换，而不是硬编码为 `docker`。

## What Changes
- 使用 `next/dynamic` 包装 `page.tsx` 中使用的 Tauri 组件 (`EnvStatus`, `ConfigForm`, `RunNextflow`) 并设置 `ssr: false`。
- 在 `ConfigForm.tsx` 中添加“Load Testdata”按钮，点击自动将 `input` 填入本地 testdata 路径，将 `outdir` 填入 `results`。
- 在 `RunNextflow.tsx`（或执行区域）增加一个下拉选择器（Profile Selector），提供 `docker` 和 `conda` 选项。
- 修改后端的 `run_nextflow` Tauri Command，使其接收前端传递的 `profile` 参数，以便动态执行 `-profile test,<profile>`。

## Impact
- Affected code:
  - `src/app/page.tsx`
  - `src/components/ConfigForm.tsx`
  - `src/components/RunNextflow.tsx`
  - `src-tauri/src/lib.rs`

## ADDED Requirements
### Requirement: 动态加载 Tauri 组件
系统必须在客户端动态加载包含 Tauri API 的组件，防止 SSR 报错。

### Requirement: 快速加载测试数据
表单需提供快捷选项来一键填充测试数据路径。

### Requirement: Profile 选择器
必须提供选择 Nextflow 执行引擎的功能（Docker / Conda）。
#### Scenario: 使用 Conda 执行测试
- **WHEN** 用户在执行区域选择 `conda` 并点击 Run
- **THEN** 后台命令动态拼接为 `nextflow run isoseq.nf -profile test,conda` 并执行。
