# Tasks
- [x] Task 1: 后端支持双模式执行
  - [x] SubTask 1.1: 在 `/Users/siyangming/nextflow_nf_core/nextflow.app/src-tauri/src/lib.rs` 中，修改 `run_nextflow` 接收 `mode: String`。
  - [x] SubTask 1.2: 根据 `mode` 拼接不同的 `Command` 参数（`local` 用 `-c conf/test_local.config run main.nf`，`online` 用 `run isoseq.nf`）。
- [x] Task 2: 前端新增模式选择器
  - [x] SubTask 2.1: 在 `/Users/siyangming/nextflow_nf_core/nextflow.app/src/components/RunNextflow.tsx` 添加 state `mode`（默认 `"local"` 或 `"online"`）。
  - [x] SubTask 2.2: 在 UI 增加 `select` 控件以选择 Execution Mode（Local Data / Online Data）。
  - [x] SubTask 2.3: 更新 `invoke("run_nextflow", { mode, profile })` 的调用参数。

# Task Dependencies
无
