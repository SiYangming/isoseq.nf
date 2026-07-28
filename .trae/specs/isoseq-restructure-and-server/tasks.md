# Tasks

- [x] Task 1: 创建 `samplesheets/` 目录并迁移所有 `testdata/samplesheet*.csv` 文件
  - [x] SubTask 1.1: 在 `isoseq.nf/` 下新建 `samplesheets/` 目录
  - [x] SubTask 1.2: 将 `testdata/samplesheet.csv`、`testdata/samplesheet_local.csv`、`testdata/samplesheet_lima_entrypoint.csv`、`testdata/samplesheet_lima_entrypoint_local.csv` 移动到 `samplesheets/`
  - [x] SubTask 1.3: 将 `testdata/samplesheet_isoseq3_refine_entrypoint.csv`、`testdata/samplesheet_isoseq3_refine_entrypoint_local.csv`、`testdata/samplesheet_bamtools_convert_entrypoint.csv`、`testdata/samplesheet_bamtools_convert_entrypoint_local.csv` 移动到 `samplesheets/`
  - [x] SubTask 1.4: 将 `testdata/samplesheet_map_entrypoint.csv`、`testdata/samplesheet_map_entrypoint_local.csv` 移动到 `samplesheets/`
  - [x] SubTask 1.5: 同步 `assets/samplesheet*.csv`（`samplesheet.csv`、`samplesheet_lima_entrypoint.csv`、`samplesheet_map_entrypoint.csv`）保留在 `assets/`（nf-schema 校验用）
  - [x] SubTask 1.6: 同步 `assets/samplesheet_lima_entrypoint.csv` 中 `testdata/alz.ccs.bam` 路径更新

- [x] Task 2: 新建 `conf/server.config`
  - [x] SubTask 2.1: 定义 `params.fasta_base_path = "/data1/users/siyangming/FASTA"`
  - [x] SubTask 2.2: 定义 `params.genomes{}` 映射（GRCh38、hg38、GRCh37、hg19、mm10、TAIR10、IRGSP-1.0、Sscrofa10.2、susScr3 共 9 个核心物种）
  - [x] SubTask 2.3: 定义 `executor` 全局资源（`cpus = 96, memory = '400 GB', queueSize = 20`，与 circdna.nf 一致）
  - [x] SubTask 2.4: 定义 `process` 资源覆盖（PBCCS、PICARD_SPLITSAMBYNUMBEROFREADS、PICARD_FILENAME、LIMA、ISOSEQ_REFINE、BAMTOOLS_CONVERT、GSTAMA_POLYACLEANUP、MINIMAP2_ALIGN、ULTRA_INDEX、ULTRA_ALIGN、GNU_SORT、GUNZIP、GSTAMA_COLLAPSE、GSTAMA_MERGE、GSTAMA_FILELIST、CUSTOM_DUMPSOFTWAREVERSIONS）
  - [x] SubTask 2.5: 启用 Docker（`docker { enabled = true, fixOwnership = true }`），关闭 conda / singularity

- [x] Task 3: 新建 `conf/large_genome.config`
  - [x] SubTask 3.1: 为 `MINIMAP2_ALIGN` 配置 `memory = '128 GB'`, `cpus = 32`, `time = '48.h'`
  - [x] SubTask 3.2: 为 `ULTRA_INDEX` 配置 `memory = '128 GB'`, `cpus = 32`, `time = '24.h'`
  - [x] SubTask 3.3: 为 `ULTRA_ALIGN` 配置 `memory = '128 GB'`, `cpus = 32`, `time = '48.h'`
  - [x] 备注：pipeline 中无 `BWA_INDEX` 过程（已从 spec 中移除该引用）

- [x] Task 4: 新建 `conf/igenomes_ignored.config`
  - [x] SubTask 4.1: 仅声明 `params.genomes = [:]`，避免 `genomeExistsError` 抛错

- [x] Task 5: 更新 `nextflow.config`
  - [x] SubTask 5.1: 升级 `manifest.nextflowVersion = '!>=25.04.8'`
  - [x] SubTask 5.2: 升级 `manifest.version = '3.0.1'`
  - [x] SubTask 5.3: 移除 `params.pipelines_testdata_base_path`
  - [x] SubTask 5.4: 新增 `params.fasta_base_path = null` 默认值
  - [x] SubTask 5.5: 新增 `params.large_genome = false` 默认值
  - [x] SubTask 5.6: 在 `profiles{}` 新增 `server`、`server_large_genome`、`test_local`、`large_genome` 入口
  - [x] SubTask 5.7: 替换 `plugins { id 'nf-validation@1.1.3' }` 为 `plugins { id 'nf-schema@2.5.1' }`
  - [x] SubTask 5.8: 调整 igenomes includeConfig 为 `if (!params.igenomes_ignore) { includeConfig 'conf/igenomes.config' } else { includeConfig 'conf/igenomes_ignored.config' }`

- [x] Task 6: 简化 `conf/base.config`
  - [x] SubTask 6.1: 移除文件内 `check_max` 闭包定义（与 circdna.nf/base.config 对齐）
  - [x] SubTask 6.2: 保留所有 `withLabel:process_*` 与 `withLabel:error_*` 块

- [x] Task 7: 更新 `conf/test*.config` 路径（10 个文件）
  - [x] SubTask 7.1: `test_local.config`：`./testdata/samplesheet_local.csv` → `./samplesheets/samplesheet_local.csv`
  - [x] SubTask 7.2: `test_lima_entrypoint_local.config`：`./testdata/samplesheet_lima_entrypoint_local.csv` → `./samplesheets/samplesheet_lima_entrypoint_local.csv`
  - [x] SubTask 7.3: `test_isoseq3_refine_entrypoint_local.config`：同步路径
  - [x] SubTask 7.4: `test_bamtools_convert_entrypoint_local.config`：同步路径
  - [x] SubTask 7.5: `test_minimap2_local.config`、`test_minimap2_map_entrypoint_local.config`、4 个 `test_ultra_*_local.config`：同步路径
  - [x] SubTask 7.6: 远程 URL 保持不变

- [x] Task 8: 更新 `isoseq.nf/main.nf` 和 `subworkflows/local/utils_nfcore_isoseq_pipeline/main.nf`（nf-schema 插件迁移）
  - [x] SubTask 8.1: `paramsSummaryMap` 已从 `plugin/nf-validation` 改为 `plugin/nf-schema`
  - [x] SubTask 8.2: `fromSamplesheet` 已从 `plugin/nf-validation` 改为 `plugin/nf-schema`
  - [x] 附加：`subworkflows/nf-core/utils_nfvalidation_plugin/main.nf` 的 `paramsHelp` / `paramsSummaryLog` / `validateParameters` 一并从 `plugin/nf-validation` 改为 `plugin/nf-schema`

- [x] Task 9: 更新 `CHANGELOG.md`
  - [x] SubTask 9.1: 在 `## 3.0.1 - [2026-07-28]` 下添加 7 条 `### Enhancements & fixes` 条目

- [x] Task 10: 新建 `SERVER_RUN_GUIDE.md`
  - [x] SubTask 10.1: 服务器连接 / 同步 FASTA / 按物种运行命令（GRCh38/hg38/TAIR10/IRGSP-1.0/Sscrofa10.2/susScr3）/ entrypoint 用法 / 自定义 fasta / screen 操作 / 注意事项 / 故障排查

# Task Dependencies
- [Task 5] 依赖 [Task 2、3、4] 完成（nextflow.config 引用新 config 文件）
- [Task 7] 依赖 [Task 1] 完成（路径才有新目标）
- [Task 9] 在所有代码变更完成后进行
- [Task 10] 在 [Task 2] 完成后进行（需参考 server.config 内容）
