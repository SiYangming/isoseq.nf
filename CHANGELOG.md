# nf-core/isoseq: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 3.1.1 - [2026-08-17]

### Enhancements & fixes

- **Lint 修复**: 解决全部 `nextflow lint` 警告（90 → 0）：`Channel` 工厂统一改为小写 `channel`，隐式闭包参数 `it` 全部显式化，单 emit 名称省略（`main.nf` 与各 subworkflow），未使用变量删除（模块 stub 块、`workflows/isoseq.nf` 未用 `ch_multiqc_custom_methods_description`），`catch (all)` 改用具名参数并实际使用，`take` 未用参数 `_input` 前缀。
- **样本表重命名**: `samplesheets/samplesheet.csv` 重命名为 `test_online.csv`（在线 alz 测试数据），`samplesheets/samplesheet_T6.csv` 重命名为 `T6.csv`；同步更新 `conf/server.config`、`conf/large_genome.config`、`scripts/run_T6.sh`、`docs/usage.md`、`SERVER_RUN_GUIDE.md` 中的引用。
- **T6 数据集配置整合**: 删除独立的 `conf/T6.config` 与 `T6` profile，T6 数据集改为通过 `server` profile + 命令行参数运行（`--genome Oryza_sativa --input samplesheets/T6.csv --aligner ultra --entrypoint isoseq3_refine ...`），与 `circdna.nf`/`fetchngs.nf` 的 server 配置约定一致。
- **运行脚本**: 更新 `scripts/run_T6.sh`（改为 server profile + CLI 参数模式）与 `scripts/run_td2.sh`（TD2 ORF 预测下游脚本）。

## 3.1.0 - [2026-08-16]

### Enhancements & fixes

- **New Entrypoint `flair`**: 从 `bio.nf` 整合 FLAIR 全长转录本分析流程（`flair align` -> `correct` -> `collapse`），支持以 fastq/fasta 全长转录本 reads 直接启动，兼容 ONT 与 PacBio（覆盖 NCBI 仅提供 fastq 而无法走 `isoseq3 refine` 的 Iso-Seq 数据场景）。
- **测试数据**: 新增 `testdata/alz.isoseq_refine.fastq`，由 `testdata/alz.isoseq_refine.bam` 转换（2918 条 FLNC reads），用于 `flair` entrypoint 测试。
- **模块收归**: `flair`、`longshot`、`minimap2/align`（nf-core 标准版）及子流程 `flair_pipeline`、`minimap2_longshot_flair` 已从 `bio.nf` 迁入 `nanoseq.nf/modules/local` 统一管理；`bio.nf` 不再作为第三方模块中转站（AGENTS.md 第 12 节）。

### `Added`

- 新增 `conf/test_flair_entrypoint.config` 与 `samplesheets/test_flair_entrypoint.csv` 测试配置。
- `nextflow_schema.json` `entrypoint` 枚举新增 `flair`。

## 3.0.1 - [2026-07-28]

### Enhancements & fixes

- **Directory restructure**: Centralised all sample sheets (including test data) into `samplesheets/` for consistency with `circdna.nf`; legacy `testdata/samplesheet*.csv` paths in test profiles now resolve to `samplesheets/samplesheet*.csv`.
- **Server profile**: Added `server` profile loading `conf/server.config` with FASTA base path, 9-species genome map (GRCh38/hg38/GRCh37/hg19/mm10/TAIR10/IRGSP-1.0/Sscrofa10.2/susScr3), `local` executor (96 CPUs / 400 GB), per-process resource limits and Docker engine configuration.
- **Large-genome profile**: Added `large_genome` config (composable with `server` via `server_large_genome`) to raise memory/time ceilings for `MINIMAP2_ALIGN`, `ULTRA_INDEX`, `ULTRA_ALIGN`, `PBCCS`, `LIMA`, `ISOSEQ_REFINE`, `GSTAMA_COLLAPSE`, `GSTAMA_MERGE` (no `BWA_INDEX` in this pipeline).
- **`igenomes_ignored` config**: New `conf/igenomes_ignored.config` provides empty `params.genomes` so the pipeline no longer fails `genomeExistsError` when `--igenomes_ignore` is used.
- **Plugin upgrade**: Replaced `nf-validation@1.1.3` with `nf-schema@2.5.1`; updated `paramsSummaryMap` / `fromSamplesheet` imports in `utils_nfcore_isoseq_pipeline` and `paramsHelp` / `paramsSummaryLog` / `validateParameters` imports in `utils_nfvalidation_plugin` accordingly.
- **Manifest bump**: `manifest.nextflowVersion` raised to `!>=25.04.8` (aligned with `circdna.nf`); deprecated `params.pipelines_testdata_base_path` removed in favour of local `samplesheets/`.
- **Documentation**: Added `SERVER_RUN_GUIDE.md` with per-genome server run commands, FASTA sync instructions and `screen` operations.

## v3.0.0 - Yangming Si [10/01/2026]

Implement LIMA entrypoint and fix various bugs.

### `Added`

- **New Entrypoint**: `lima`
  - Allows starting the pipeline from CCS BAM files.
  - Includes `PICARD_SPLITSAMBYNUMBEROFREADS` for splitting large BAM files into chunks.
  - Includes `PICARD_FILENAME` for renaming split files to `{sample}.chunk{num}.bam` format.
  - Seamless integration with existing `LIMA` -> `ISOSEQ_REFINE` -> `BAMTOOLS_CONVERT` -> `GSTAMA_POLYACLEANUP` workflow.
- **Documentation**:
  - Added `LIMA_ENTRYPOINT_USAGE.md` with detailed usage instructions.
  - Added `CHANGES_SUMMARY_CN.md` summarizing the changes.
- **Configuration**:
  - Updated `nextflow_schema.json` to include `lima` in `entrypoint` enum.
  - Added `samplesheets/samplesheet_lima_entrypoint.csv` for testing.

### `Fixed`

- **GSTAMA_FILELIST Module**:
  - Fixed "No such variable: i" error by escaping the variable in comments (`$i` -> `\$i`).
- **PICARD Modules**:
  - Modified `PICARD_SPLITSAMBYNUMBEROFREADS` to output to current directory (`.`) instead of hardcoded path, fixing "Directory does not exist" error.
  - Updated `publishDir` configuration in `conf/modules.config`:
    - Disabled publication of intermediate split files from `PICARD_SPLITSAMBYNUMBEROFREADS`.
    - Configured `PICARD_FILENAME` to publish renamed files to `params.outdir` without subdirectories.
    - Ensured only renamed files (`*.chunk*.bam`) are kept in the results.
- **Workflow**:
  - Fixed missing `chunk_num` workflow output error.
  - Defined default `params.monochromeLogs` to silence warnings.

### `Dependencies`

- Added `picard/splitsambynumberofreads` module (biocontainers/picard:3.4.0).
- Added `picard/filename` local module (ubuntu:20.04).

## v2.0.0 - Sapphire Duck [05/09/2024]

New entrypoint option to skip isoseq pre-processing.
Update the pipeline to nf-core 2.14.1.
Update modules.
nf-validation version pinned [PR25](https://github.com/nf-core/isoseq/issues/25)
Upgrade from isoseq3 to isoseq (version 4) Fix segmentation fault [PR27](https://github.com/nf-core/isoseq/issues/27)
Add alternative entrypoint [PR10](https://github.com/nf-core/isoseq/issues/10)

### `Added`

A new entreypoint system has been implemented to allow the user where to start the analysis.
The `isoseq` entrypoint runs the full pipeline.
The `map` entrypoint runs the pipeline from the mapping step.
This new `entreypoint` option make possible to use the isoseq pipeline for analysis PacBio data when subreads are not provided, or for users who want to benefit from the mapping + TAMA analysis for their Nanopore data.

### `Fixed`

- Update modules to their nf-test version (bamtools/convert, custom/dumpsoftwareversions, gnu/sort, gstama/collapse/ gstama/merge, gstama/polyacleanup, gunzip, isoseq/refine, lima, minimap2/align, pbccs,ultra/align, ultra/index)
- Since isoseq3 switch to version 4, it has been rename isoseq

  | Tool             | Previous version | New version |
  | ---------------- | ---------------- | ----------- |
  | bamtools/convert | 2.5.2            | 2.5.2       |
  | isoseq           | 3.8.2            | 4.0.0       |
  | lima             | 2.7.1            | 2.9.0       |
  | minimap2/align   | 2.24             | 2.28        |
  | gnu/sort         | 8.25             | 9.3         |
  | multiqc          | 1.21             | 1.24.1      |

### `Dependencies`

### `Deprecated`

## v1.1.5 - Byzantium Buzzard [02/08/2023]

Update the pipeline to nf-core 2.9.

### `Added`

### `Fixed`

- Add gnu/sort to sort annotation before uLTRA index
- Update citations
- Add background to pipeline png
  | Tool | Previous version | New version |
  | ----------------------- | ---------------- | ----------- |
  | isoseq3 | 3.8.1 | 3.8.2 |
  | lima | 2.6.0 | 2.7.1 |
  | bamtools/convert | 2.5.1 | 2.5.2 |
  | gstama/merge | 1.0.2 | 1.0.3 |
  | uLTRA/index | 0.0.4.2 | 0.1 |
  | uLTRA/align | 0.0.4.2 | 0.1 |
  | samtools | 1.17 | 1.17 |
  | gnu/sort | ---- | 8.25 |

### `Dependencies`

### `Deprecated`

## v1.1.4 - Teal Albatross [13/03/2023]

### `Added`

### `Fixed`

- Update minimap2 path test: Don't set gtf option. It is not expected to be used with minimap2 is chosen.
- FIX: Don't prepare gtf channel when minimap2 is chosen.

### `Dependencies`

### `Deprecated`

## v1.1.3 - Blue Grouse [06/03/2023]

### `Added`

### `Fixed`

- Fix pipeline image path
- params.input invalid type if pipeline is run with local file in samplesheet (was working with URL)

### `Dependencies`

### `Deprecated`

## v1.1.2 - Gray Eagle [11/01/2023]

### `Added`

- Fix [issue #17](https://github.com/ksahlin/ultra/issues/17). Thanks to [Husen M. Umer](https://github.com/husensofteng).
- Zenodo DOI
- Update to template v2.7.2

### `Fixed`

- Remove hard coded capped option for GSTAMA_FILELIST step. Now follow user choice. Thanks to [Mazdak Salavati](https://github.com/MazdaX).

### `Dependencies`

| Tool                 | Previous version | New version |
| -------------------- | ---------------- | ----------- |
| isoseq3              | 3.4.0            | 3.8.1       |
| lima                 | 2.2.0            | 2.6.0       |
| minimap2             | 2.21             | 2.24        |
| samtools             | 1.12             | 1.14        |
| multiqc              | 1.13             | 1.14        |
| pbccs                | 6.2.0            | 6.4.0       |
| ultra_bioinformatics | 0.0.4            | 0.0.4.2     |
| samtools             | 1.15.1           | 1.16.1      |

### `Deprecated`

## v1.1.1 - White Hawk [26/09/2022]

Update the pipeline to nf-core 2.5.1, update modules, and fix documentation.

### `Added`

### `Fixed`

- Documentation: Correct aligner option documentation

### `Dependencies`

- Update `samplesheet_check` module
- Update `dumpsoftwareversion` module
- Update `MultiQC` module

### `Deprecated`

## v1.1.0 - Black Crow [12/07/2022]

Improves computation time.
Split `uLTRA pipeline` into two processes, `uLTRA index` and `uLTRA align`. `GTF` index is computed once and not `chunk` times.
`uLTRA align` sort and convert `sam` output into `bam` files. Aligned reads are already sorted by `minimap2` module. Therefore, `samtools sort` module is not needed anymore and has been removed.
The `bioperl` module objective was to deal with [spurious alignments produced by uLTRA if a malformed GTF is used](https://github.com/ksahlin/ultra/issues/11). Removing it will stop the pipeline in case of malformed `GTF`.
Module resource requirements have been revised for four modules (`gstama/merge`, `isoseq3/refine`, `lima`, `ultra/align`) to reduce requested resources.
AWS runs with shows better run time and CPU/RAM usage ([Results](docs/images/Isoseq_pipeline_v1.0.0_v1.1.0.png)).

### `Added`

- Add `uLTRA index` and `uLTRA align` to replace `uLTRA pipeline` [PR 1830](https://github.com/nf-core/modules/pull/1830)
- Module resources adjustments: `gstama/merge`, `isoseq3/refine`, `lima`, `ultra/align` [PR1858](https://github.com/nf-core/modules/pull/1858), `gunzip`, `MultiQC`

### `Fixed`

### `Dependencies`

### `Deprecated`

- Remove `uLTRA pipeline`
- Remove `samtools sort` module
- Remove `bioperl` module

## v1.0.0 - Silver Swan [28/06/2022]

Initial release of nf-core/isoseq, created with the [nf-core](https://nf-co.re/) template.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`
