# LIMA Entrypoint 使用指南

## 概述

新增的 `lima` entrypoint 允许从已经过 CCS 处理的 BAM 文件开始运行 Isoseq 流程。这对于以下场景特别有用：
- 您已经有 CCS BAM 文件（来自外部工具或之前的运行）
- 需要重新运行 LIMA 步骤及后续分析
- 想要使用 Picard 将大型 CCS BAM 文件拆分成多个块以加速处理

## 流程说明

使用 `lima` entrypoint 时，流程执行顺序为：

1. **PICARD_SPLITSAMBYNUMBEROFREADS**: 将输入的 CCS BAM 文件拆分为指定数量的子文件
2. **PICARD_FILENAME**: 重命名拆分后的 BAM 文件为 `{sample_name}.chunk{num}.bam` 格式
3. **LIMA**: 从 CCS 中去除引物序列
4. **ISOSEQ_REFINE**: 去除没有 polyA 尾的 CCS，并从其他序列中移除 polyA 尾
5. **BAMTOOLS_CONVERT**: 将 BAM 转换为 FASTA
6. **GSTAMA_POLYACLEANUP**: 清理读段中的 polyA 尾
7. **后续比对和 TAMA 处理**: 与标准流程相同

## 使用方法

### 1. 准备 Samplesheet

创建一个 CSV 文件，包含以下列：
- `sample`: 样本名称
- `bam`: CCS BAM 文件路径
- `pbi`: 设置为 `None`（不需要 PacBio 索引文件）

示例 samplesheet (`samplesheet_lima.csv`):
```csv
sample,bam,pbi
alz,testdata/alz.ccs.bam,None
T6,/path/to/T6-R.Iso_bc01.bcM0001.ISO.bam,None
```

### 2. 运行命令

基本命令：
```bash
nextflow run main.nf \
  --input samplesheet_lima.csv \
  --entrypoint lima \
  --primers primers.fasta \
  --fasta genome.fasta \
  --gtf genome.gtf \
  --outdir results \
  --chunk 40
```

### 3. 参数说明

- `--entrypoint lima`: 指定使用 lima entrypoint
- `--chunk 40`: 将每个 CCS BAM 文件拆分为 40 个子文件（默认值：40）
- `--primers`: 引物序列文件（FASTA 格式）
- `--fasta`: 参考基因组序列
- `--gtf`: 基因组注释文件（使用 uLTRA 比对器时需要）
- `--aligner`: 比对器选择（`minimap2` 或 `ultra`，默认：`minimap2`）

### 4. 测试运行

使用项目提供的测试数据：
```bash
nextflow run main.nf \
  --input assets/samplesheet_lima_entrypoint.csv \
  --entrypoint lima \
  --primers /path/to/primers.fasta \
  --fasta /path/to/genome.fasta \
  --outdir test_lima_results \
  --chunk 40
```

## 技术细节

### Picard 拆分过程

输入文件会通过 Picard SplitSamByNumberOfReads 工具处理：
```bash
picard SplitSamByNumberOfReads \
  INPUT=input.ccs.bam \
  OUTPUT=output_dir \
  OUT_PREFIX=sample_name \
  SPLIT_TO_N_FILES=40 \
  VALIDATION_STRINGENCY=SILENT
```

### 文件重命名

拆分后的文件会从 Picard 默认格式 `{prefix}_0001.bam`, `{prefix}_0002.bam` 等重命名为：
```
{sample_name}.chunk1.bam
{sample_name}.chunk2.bam
...
{sample_name}.chunk40.bam
```

这个格式与后续 LIMA 流程的期望输入格式一致。

### 环境配置

- **PICARD_SPLITSAMBYNUMBEROFREADS**: 使用 nf-core 模块，容器：`biocontainers/picard:3.4.0`
- **PICARD_FILENAME**: 使用本地模块，容器：`ubuntu:20.04`（与 GSTAMA_FILELIST 相同）

## 与其他 Entrypoint 的比较

| Entrypoint | 起始点 | 输入文件类型 | 主要用途 |
|-----------|--------|------------|---------|
| `isoseq` (默认) | 原始 subreads | BAM + PBI | 完整流程，从原始数据开始 |
| `lima` (新增) | CCS BAM | CCS BAM | 从 CCS 开始，包含拆分、LIMA 及后续分析 |
| `map` | 已处理的 FASTA | FASTA.GZ | 仅执行比对和 TAMA 分析 |

## 输出结果

输出目录结构与标准 `isoseq` entrypoint 相同，包括：
- LIMA 处理后的 BAM 文件
- ISOSEQ_REFINE 结果
- 比对结果（SAM/BAM）
- TAMA collapse 和 merge 结果
- MultiQC 报告

## 注意事项

1. 确保输入的 BAM 文件是 CCS（Circular Consensus Sequences）处理后的文件
2. `--chunk` 参数决定拆分的文件数量，建议根据数据大小和可用计算资源调整
3. 引物文件 (`--primers`) 必须提供，因为 LIMA 步骤需要
4. 如果使用 `--aligner ultra`，则必须提供 GTF 文件

## 故障排除

### 错误：文件未找到
- 检查 samplesheet 中的路径是否正确
- 确保使用绝对路径或相对于工作目录的正确路径

### 错误：LIMA 失败
- 检查引物文件格式是否正确（FASTA 格式）
- 确认 CCS BAM 文件质量良好

### 性能优化
- 增加 `--chunk` 值以提高并行度（建议：20-80）
- 根据可用内存调整 Picard 的内存设置（在 `nextflow.config` 中）

## 相关文件

- 主工作流: `workflows/isoseq.nf`
- PICARD_FILENAME 模块: `modules/local/picard/filename/main.nf`
- PICARD_SPLITSAMBYNUMBEROFREADS: `modules/nf-core/picard/splitsambynumberofreads/main.nf`
- 测试 samplesheet: `assets/samplesheet_lima_entrypoint.csv`
- Schema 配置: `nextflow_schema.json`
