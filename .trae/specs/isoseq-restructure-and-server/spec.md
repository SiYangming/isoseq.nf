# isoseq.nf 重构与服务器配置 Spec

## Why

`isoseq.nf` 当前结构与 `circdna.nf` 不一致：测试样本表散落在 `testdata/` 目录下、缺少服务器生产环境配置（FASTA 基础路径、物种基因组映射、执行器资源）、没有可复用的服务器运行指南。本 spec 统一两个 pipeline 的目录结构、补充服务器生产配置，并参考 `circdna.nf/SERVER_RUN_GUIDE.md` 提供 isoseq 专用服务器运行指南，方便用户在服务器上批量运行 Iso-Seq 分析。

## What Changes

- **新建** `isoseq.nf/samplesheets/` 目录，将 `testdata/` 下的全部 10 个 `samplesheet*.csv` 文件移动到该目录（包括：`samplesheet.csv`、`samplesheet_local.csv`、`samplesheet_lima_entrypoint.csv`、`samplesheet_lima_entrypoint_local.csv`、`samplesheet_isoseq3_refine_entrypoint.csv`、`samplesheet_isoseq3_refine_entrypoint_local.csv`、`samplesheet_bamtools_convert_entrypoint.csv`、`samplesheet_bamtools_convert_entrypoint_local.csv`、`samplesheet_map_entrypoint.csv`、`samplesheet_map_entrypoint_local.csv`）
- **新建** `isoseq.nf/conf/server.config`：包含 `fasta_base_path`、`params.genomes` 物种映射（GRCh38/hg38/GRCh37/Sscrofa10.2/IRGSP-1.0/TAIR10 等）、`executor` 全局资源限制、各 process 的资源/参数覆盖、Docker 引擎配置
- **新建** `isoseq.nf/conf/large_genome.config`：针对大基因组（susScr3、bosTau8 等）增加 `BWA_INDEX`、`MINIMAP2_ALIGN`、`ULTRA_ALIGN` 的资源上限，参考 circdna.nf 的大基因组策略
- **新建** `isoseq.nf/conf/igenomes_ignored.config`：当 `params.igenomes_ignore = true` 时提供空 `params.genomes`，避免 `genomeExistsError` 抛错
- **新建** `isoseq.nf/SERVER_RUN_GUIDE.md`：服务器登录、FASTA 同步、按基因组/物种运行命令、screen 常用操作、注意事项（参考 `circdna.nf/SERVER_RUN_GUIDE.md` 结构）
- **修改** `isoseq.nf/nextflow.config`：
  - `manifest.nextflowVersion` 升级为 `!>=25.04.8`（与 circdna.nf 一致）
  - `manifest.version` 从 `3.0.0` 升级为 `3.0.1`（PATCH 级别 — 结构性重构不引入新功能）
  - 移除 `params.pipelines_testdata_base_path`（使用本地 samplesheets 替代远程地址）
  - 新增 `params.fasta_base_path`、`params.bam_base_path` 默认值
  - 新增 `params.large_genome` 布尔参数
  - 在 `profiles{}` 中新增 `server { includeConfig 'conf/server.config' }`、`server_large_genome { includeConfig 'conf/server.config' ; includeConfig 'conf/large_genome.config' }` 入口
  - 在 `profiles{}` 中新增 `test_local { includeConfig 'conf/test_local.config' }`
  - 在 `profiles{}` 中新增 `large_genome { includeConfig 'conf/large_genome.config' }`
  - 将 `plugins { id 'nf-validation@1.1.3' }` 替换为 `plugins { id 'nf-schema@2.5.1' }`（与 circdna.nf 一致，行为兼容：`fromSamplesheet` 在 nf-schema 中同样可用）
  - `includeConfig` igenomes 改为 circdna.nf 风格的 `if/else` 模式
- **修改** `isoseq.nf/conf/base.config`：
  - 移除文件内的 `check_max` 函数定义（已移入 `nextflow.config` 的 profiles 或 default）
  - 保留所有 `withLabel:process_*` 块与 `withLabel:error_*` 块
  - 与 circdna.nf/base.config 保持结构一致（直读 `params.max_cpus` / `params.max_memory`）
- **修改** 全部 `conf/test*.config`（10 个文件）：将 `input = .../testdata/samplesheet*.csv` 路径改为 `.../samplesheets/samplesheet*.csv`；远程 URL 改为本地 samplesheets 路径（因为我们将本地文件统一到 samplesheets/）
- **修改** `isoseq.nf/CHANGELOG.md`：在版本 `3.0.1` 下添加条目，记录结构重构、服务器配置、样本表目录迁移、SERVER_RUN_GUIDE
- **修改** `isoseq.nf/nextflow_schema.json`（若 nf-schema 校验需要）：移除对 `pipelines_testdata_base_path` 的引用

**BREAKING Changes**：
- 所有测试 profile 的 `input` 路径变化（`testdata/samplesheet*.csv` → `samplesheets/samplesheet*.csv`）。`test`/`test_full` profile 仍使用远程 URL（这些 URL 来自 `nf-core/test-datasets`），不受影响。

## Impact

- Affected specs: 无（新增 spec）
- Affected code:
  - `isoseq.nf/samplesheets/`（新建）
  - `isoseq.nf/conf/server.config`（新建）
  - `isoseq.nf/conf/large_genome.config`（新建）
  - `isoseq.nf/conf/igenomes_ignored.config`（新建）
  - `isoseq.nf/SERVER_RUN_GUIDE.md`（新建）
  - `isoseq.nf/nextflow.config`（修改）
  - `isoseq.nf/conf/base.config`（修改）
  - `isoseq.nf/conf/test*.config`（10 个文件路径修改）
  - `isoseq.nf/CHANGELOG.md`（修改）
  - `isoseq.nf/nextflow_schema.json`（可能需要 `nf-core schema build` 重新生成）

## ADDED Requirements

### Requirement: samplesheets 目录统一管理

The system SHALL 统一管理所有样本表（包括测试样本）到 `samplesheets/` 目录，与 `circdna.nf/samplesheets/` 命名规范保持一致。

#### Scenario: 测试样本可访问
- **WHEN** 用户运行 `nextflow run main.nf -profile test_local`
- **THEN** pipeline 能正确读取 `samplesheets/samplesheet_local.csv` 中的本地测试数据路径

#### Scenario: 服务器样本可访问
- **WHEN** 用户运行 `nextflow run main.nf -profile server --input samplesheets/Homo_sapiens_GRCh38_isoseq.csv`
- **THEN** pipeline 能正确处理该样本表

### Requirement: 服务器配置 profile

The system SHALL 提供 `server` profile，加载 `conf/server.config`，配置好 FASTA 基础路径、物种基因组映射、执行器资源限制。

#### Scenario: 服务器使用 genome 参数
- **WHEN** 用户运行 `nextflow run main.nf -profile server --genome GRCh38 --input samplesheets/samplesheet.csv --outdir /data1/.../results`
- **THEN** pipeline 能从 `${params.fasta_base_path}/Homo_sapiens/NCBI/GRCh38/.../genome.fa` 加载参考基因组

#### Scenario: 通过 fasta 参数直接指定
- **WHEN** 用户运行 `nextflow run main.nf -profile server --fasta /custom/path/genome.fa --input samplesheets/samplesheet.csv`
- **THEN** pipeline 使用用户提供的 fasta 路径，跳过 `genomes{}` 映射

### Requirement: 大基因组配置

The system SHALL 提供 `large_genome` 配置（可与 server profile 叠加），为 `BWA_INDEX`、`MINIMAP2_ALIGN`、`ULTRA_ALIGN`、`GNU_SORT` 提供更大内存和时间限制。

#### Scenario: 大基因组运行
- **WHEN** 用户运行 `nextflow run main.nf -profile server -c conf/large_genome.config --genome susScr3 --input samplesheets/samplesheet.csv`
- **THEN** pipeline 为相关 process 分配 ≥128GB 内存与 ≥24h 时间

### Requirement: SERVER_RUN_GUIDE

The system SHALL 提供 `SERVER_RUN_GUIDE.md`，包含服务器登录、FASTA 上传、按基因组/物种运行命令、screen 操作、注意事项。

#### Scenario: 文档可读
- **WHEN** 用户在服务器上查阅 `SERVER_RUN_GUIDE.md`
- **THEN** 用户能直接复制粘贴命令运行 Iso-Seq pipeline

## MODIFIED Requirements

### Requirement: 插件升级（nf-validation → nf-schema）

将 `nextflow.config` 中的 `plugins { id 'nf-validation@1.1.3' }` 改为 `plugins { id 'nf-schema@2.5.1' }`。

迁移点：
- `Channel.fromSamplesheet("input")` 在 nf-schema 中仍然可用
- `UTILS_NFVALIDATION_PLUGIN` subworkflow 需要替换为 `UTILS_NFVALIDATION_PLUGIN`（在 nf-schema 2.x 中仍然提供该 subworkflow，名字不变）
- `paramsSummaryMap` 从 `plugin/nf-validation` 改为 `plugin/nf-schema`

### Requirement: 测试样本表路径

所有 `conf/test*.config` 中的 `input` 路径：
- `test_local.config`：`./testdata/samplesheet_local.csv` → `./samplesheets/samplesheet_local.csv`
- `test_lima_entrypoint_local.config`：`./testdata/samplesheet_lima_entrypoint_local.csv` → `./samplesheets/samplesheet_lima_entrypoint_local.csv`
- `test_isoseq3_refine_entrypoint_local.config`：`./testdata/samplesheet_isoseq3_refine_entrypoint_local.csv` → `./samplesheets/samplesheet_isoseq3_refine_entrypoint_local.csv`
- `test_bamtools_convert_entrypoint_local.config`：`./testdata/samplesheet_bamtools_convert_entrypoint_local.csv` → `./samplesheets/samplesheet_bamtools_convert_entrypoint_local.csv`
- `test_minimap2_local.config`：`./testdata/samplesheet_map_entrypoint_local.csv` → `./samplesheets/samplesheet_map_entrypoint_local.csv`
- 其他 `_local.config`：按对应关系迁移

**远程 URL 保持不变**（`test.config`、`test_full.config`、`test_minimap2.config`、`test_lima_entrypoint.config`、`test_isoseq3_refine_entrypoint.config`、`test_bamtools_convert_entrypoint.config`、`test_minimap2_map_entrypoint.config`、`test_ultra_map_entrypoint.config`、`test_ultra_lima_entrypoint.config`、`test_ultra_isoseq3_refine_entrypoint.config`、`test_ultra_bamtools_convert_entrypoint.config`）。

## REMOVED Requirements

无

## Reference

- 参考文档：`/Users/siyangming/nextflow_nf_core/circdna.nf/SERVER_RUN_GUIDE.md`
- 参考配置：`/Users/siyangming/nextflow_nf_core/circdna.nf/conf/server.config`
- 参考配置：`/Users/siyangming/nextflow_nf_core/circdna.nf/conf/large_genome.config`
- 参考配置：`/Users/siyangming/nextflow_nf_core/circdna.nf/conf/base.config`
- 参考样本表目录：`/Users/siyangming/nextflow_nf_core/circdna.nf/samplesheets/`
- 规范：`/Users/siyangming/nextflow_nf_core/AGENTS.md`
