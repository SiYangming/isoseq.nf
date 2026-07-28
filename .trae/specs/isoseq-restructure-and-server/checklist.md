# Checklist

- [x] `isoseq.nf/samplesheets/` 目录创建完毕，10 个 `samplesheet*.csv` 文件从 `testdata/` 迁移到位（实际 11 个，含 `samplesheet_full.csv`，无副作用）
- [x] `isoseq.nf/conf/server.config` 创建完毕，包含 `fasta_base_path`、`genomes{}` 映射（GRCh38/hg38/GRCh37/hg19/mm10/TAIR10/IRGSP-1.0/Sscrofa10.2/susScr3）、`executor` 全局资源（96 CPUs / 400 GB）、`process` 资源覆盖（16 个 process）
- [x] `isoseq.nf/conf/large_genome.config` 创建完毕，针对 MINIMAP2_ALIGN / ULTRA_INDEX / ULTRA_ALIGN / PBCCS / LIMA / ISOSEQ_REFINE / GSTAMA_COLLAPSE / GSTAMA_MERGE 提供大基因组资源（pipeline 中无 `BWA_INDEX` 过程）
- [x] `isoseq.nf/conf/igenomes_ignored.config` 创建完毕，提供空 `params.genomes`
- [x] `isoseq.nf/SERVER_RUN_GUIDE.md` 创建完毕，包含服务器登录、FASTA 同步、screen 操作、按物种 / entrypoint 命令、自定义 `--fasta` 流程、故障排查表
- [x] `isoseq.nf/nextflow.config` 更新完毕：`manifest.version` → `3.0.1`、`nextflowVersion` → `!>=25.04.8`、新增 `server` / `server_large_genome` / `test_local` / `large_genome` profile、插件替换为 `nf-schema@2.5.1`、`includeConfig` igenomes 改为 `if/else` 模式
- [x] `isoseq.nf/conf/base.config` 简化完毕，移除 `check_max` 闭包（Grep 验证无残留），保留所有 `withLabel:process_*` 块
- [x] `isoseq.nf/conf/test*.config`（10 个 `_local.config`）路径全部更新为 `${launchDir}/samplesheets/samplesheet*.csv`（远程 URL 保持不变）
- [x] `isoseq.nf/CHANGELOG.md` 在 `## 3.0.1 - [2026-07-28]` 版本下添加 7 条变更记录
- [x] `isoseq.nf/subworkflows/local/utils_nfcore_isoseq_pipeline/main.nf` 的 `paramsSummaryMap` / `fromSamplesheet` 已从 `plugin/nf-validation` 迁移到 `plugin/nf-schema`
- [x] `isoseq.nf/subworkflows/nf-core/utils_nfvalidation_plugin/main.nf` 的 `paramsHelp` / `paramsSummaryLog` / `validateParameters` 已从 `plugin/nf-validation` 迁移到 `plugin/nf-schema`
