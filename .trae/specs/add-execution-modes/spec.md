# Execution Modes (Local & Online) Spec

## Why
用户需要针对数据集运行 Nextflow 流程的不同模式。除了现有的基于云端/远程仓库的“在线执行”模式，还需要增加基于本地项目文件的“本地数据执行”模式。

## What Changes
- 在前端 UI（`RunNextflow.tsx`）增加执行模式选择器（Execution Mode Selector），提供“Local Data (本地数据)”和“Online Data (在线数据)”两个单选按钮或下拉选项。
- 修改后端 Rust 逻辑（`src-tauri/src/lib.rs` 的 `run_nextflow`），接受 `mode: String` 参数。
- 如果 `mode == "local"`，则切换工作目录至 `/Users/siyangming/nextflow_nf_core/isoseq.nf`，并拼接命令为：`nextflow -c conf/test_local.config run main.nf -profile <profile>`。
- 如果 `mode == "online"`，则保持原有命令结构，即 `nextflow run isoseq.nf -profile test,<profile>`。

## Impact
- Affected code:
  - `src/components/RunNextflow.tsx`
  - `src-tauri/src/lib.rs`

## ADDED Requirements
### Requirement: 多执行模式支持
应用必须支持本地执行和在线执行两种模式。

#### Scenario: 选择本地执行
- **WHEN** 用户选择“Local Data”并点击执行
- **THEN** 后台调用 `nextflow -c conf/test_local.config run main.nf`。

#### Scenario: 选择在线执行
- **WHEN** 用户选择“Online Data”并点击执行
- **THEN** 后台调用 `nextflow run isoseq.nf -profile test,<profile>`。

## MODIFIED Requirements
无

## REMOVED Requirements
无
