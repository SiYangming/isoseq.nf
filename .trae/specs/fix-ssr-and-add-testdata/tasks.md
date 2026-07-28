# Tasks
- [x] Task 1: 修复 Next.js SSR 及 Tauri API 报错
  - [x] SubTask 1.1: 在 `/Users/siyangming/nextflow_nf_core/nextflow.app/src/app/page.tsx` 中引入 `next/dynamic`。
  - [x] SubTask 1.2: 将 `EnvStatus`, `ConfigForm`, `RunNextflow` 改为动态导入（`ssr: false`）。
- [x] Task 2: 增加加载 Testdata 的默认选项
  - [x] SubTask 2.1: 在 `/Users/siyangming/nextflow_nf_core/nextflow.app/src/components/ConfigForm.tsx` 中添加 "Load Testdata" 按钮。
  - [x] SubTask 2.2: 使用 `react-hook-form` 的 `setValue` 将 `input` 和 `outdir` 填入测试默认值。
- [x] Task 3: 增加 Profile (Docker/Conda) 选择器
  - [x] SubTask 3.1: 修改 `/Users/siyangming/nextflow_nf_core/nextflow.app/src-tauri/src/lib.rs` 中的 `run_nextflow`，使其接收 `profile: String` 参数。
  - [x] SubTask 3.2: 在 `/Users/siyangming/nextflow_nf_core/nextflow.app/src/components/RunNextflow.tsx` 中引入 `<select>` 或单选组件，供用户选择 `docker` 或 `conda`。
  - [x] SubTask 3.3: 在调用 `invoke("run_nextflow", { profile })` 时传递用户选择的配置。

# Task Dependencies
无
