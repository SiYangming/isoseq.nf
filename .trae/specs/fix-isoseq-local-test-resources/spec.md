# fix-isoseq-local-test-resources Spec

## Why

在 `isoseq-restructure-and-server` 重构完成后，运行本地测试 (`-profile test_local,docker`) 时，Nextflow 因 `ULTRA_ALIGN` (label `process_medium`) 请求 36GB 内存而本机仅 16GB 可用，抛出 `Process requirement exceeds available memory` 错误并终止。同时，重复运行测试时因 `trace`/`report`/`timeline` 文件已存在而报错。

参考 `circdna.nf/conf/test_local.config` 的解决方案：需要在 `isoseq.nf/conf/test_local.config` 中覆盖 `process_medium`/`process_high`/`process_low` 的资源限制，并添加文件覆盖开关。

## What Changes

- **修改** `isoseq.nf/conf/test_local.config`：
  - 添加 `process { withLabel:process_low { cpus/memory } }` 覆盖
  - 添加 `process { withLabel:process_medium { cpus/memory } }` 覆盖（限制 ULTRA_ALIGN 等模块内存 ≤ 8GB）
  - 添加 `process { withLabel:process_high { cpus/memory } }` 覆盖
  - 添加 `trace.overwrite = true`、`report.overwrite = true`、`timeline.overwrite = true`
- **检查** 其他 `conf/*_local.config` 文件是否需要类似覆盖

## Impact

- Affected specs: 无
- Affected code:
  - `isoseq.nf/conf/test_local.config`
  - 可能的其他 `conf/*_local.config`

## ADDED Requirements

### Requirement: 本地测试资源限制覆盖

The system SHALL 在 `test_local.config` 中覆盖 `process_low`/`process_medium`/`process_high` 标签的资源，确保本地测试时内存请求不超过 `max_memory`。

#### Scenario: test_local 正常运行
- **WHEN** 用户运行 `nextflow run main.nf -profile test_local,docker --outdir results/test_isoseq`
- **THEN** `ULTRA_ALIGN` 等 `process_medium` 任务请求内存不超过 8GB， pipeline 不因资源超限而失败

### Requirement: 重复运行不报错

The system SHALL 允许重复运行测试而不因 `trace`/`report`/`timeline` 文件已存在而报错。

#### Scenario: 重复运行测试
- **WHEN** 用户多次运行同一测试命令
- **THEN** 不抛出 `FileAlreadyExistsException`

## MODIFIED Requirements

无

## REMOVED Requirements

无
