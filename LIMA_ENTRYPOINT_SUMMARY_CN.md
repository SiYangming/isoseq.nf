# LIMA Entrypoint 功能总结与使用指南

本文档整合了 LIMA Entrypoint 的使用说明、功能总结及技术实现细节。

---

## 目录

1. [版本变更说明 (v3.0.0)](#1-版本变更说明-v300)
2. [功能概述](#2-功能概述)
3. [使用指南](#3-使用指南)
4. [输出与故障排除](#4-输出与故障排除)
5. [技术实现详解](#5-技术实现详解)
6. [修改文件列表](#6-修改文件列表)

---

## 1. 版本变更说明 (v3.0.0)

**版本**: v3.0.0 - Yangming Si [10/01/2026]

本次更新主要包含 LIMA entrypoint 的实现及多个关键 bug 的修复。

### 核心变更

1. **新增 LIMA Entrypoint**:
   - 允许直接从 CCS BAM 文件启动流程。
   - 包含 `PICARD_SPLITSAMBYNUMBEROFREADS` 模块，支持将大文件拆分为多个 chunk。
   - 包含 `PICARD_FILENAME` 模块，自动重命名文件为 `{sample}.chunk{num}.bam` 格式。

2. **文档更新**:
   - 新增本文档，提供详细的使用指南和技术总结。
   - 更新 `CHANGELOG.md`，记录 v3.0.0 版本的详细变更。

3. **Bug 修复**:
   - 修复 `GSTAMA_FILELIST` 模块中的变量转义错误 ("No such variable: i")。
   - 修复 `PICARD_SPLITSAMBYNUMBEROFREADS` 的路径问题，解决了 "Directory does not exist" 错误。
   - 优化 `publishDir` 配置，确保只输出重命名后的 chunk 文件，保持结果目录整洁。

详细的变更日志请查看 [CHANGELOG.md](CHANGELOG.md)。

---

## 2. 功能概述

新增的 `lima` entrypoint 允许从已经过 CCS 处理的 BAM 文件开始运行 Isoseq 流程。这对于以下场景特别有用：
- 您已经有 CCS BAM 文件（来自外部工具或之前的运行）
- 需要重新运行 LIMA 步骤及后续分析
- 想要使用 Picard 将大型 CCS BAM 文件拆分成多个块以加速处理

### 与其他 Entrypoint 的比较

| Entrypoint | 起始点 | 输入文件类型 | 主要用途 |
|-----------|--------|------------|---------|
| `isoseq` (默认) | 原始 subreads | BAM + PBI | 完整流程，从原始数据开始 |
| `lima` (新增) | CCS BAM | CCS BAM | 从 CCS 开始，包含拆分、LIMA 及后续分析 |
| `map` | 已处理的 FASTA | FASTA.GZ | 仅执行比对和 TAMA 分析 |

---

## 3. 使用指南

### 3.1 流程说明

使用 `lima` entrypoint 时，流程执行顺序为：

1. **PICARD_SPLITSAMBYNUMBEROFREADS**: 将输入的 CCS BAM 文件拆分为指定数量的子文件
2. **PICARD_FILENAME**: 重命名拆分后的 BAM 文件为 `{sample_name}.chunk{num}.bam` 格式
3. **LIMA**: 从 CCS 中去除引物序列
4. **ISOSEQ_REFINE**: 去除没有 polyA 尾的 CCS，并从其他序列中移除 polyA 尾
5. **BAMTOOLS_CONVERT**: 将 BAM 转换为 FASTA
6. **GSTAMA_POLYACLEANUP**: 清理读段中的 polyA 尾
7. **后续比对和 TAMA 处理**: 与标准流程相同

### 3.2 准备 Samplesheet

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

### 3.3 运行命令

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

### 3.4 参数说明

- `--entrypoint lima`: 指定使用 lima entrypoint
- `--chunk 40`: 将每个 CCS BAM 文件拆分为 40 个子文件（默认值：40）
- `--primers`: 引物序列文件（FASTA 格式）
- `--fasta`: 参考基因组序列
- `--gtf`: 基因组注释文件（使用 uLTRA 比对器时需要）
- `--aligner`: 比对器选择（`minimap2` 或 `ultra`，默认：`minimap2`）

### 3.5 测试运行

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

---

## 4. 输出与故障排除

### 4.1 输出结果

输出目录结构与标准 `isoseq` entrypoint 相同，但包含特定于 lima entrypoint 的中间结果：
- `01_PICARD_SPLITSAMBYNUMBEROFREADS/`: 包含重命名后的拆分 BAM 文件（`*.chunk*.bam`）。原始 Picard 输出文件不保留。
- LIMA 处理后的 BAM 文件
- ISOSEQ_REFINE 结果
- 比对结果（SAM/BAM）
- TAMA collapse 和 merge 结果
- MultiQC 报告

### 4.2 注意事项

1. 确保输入的 BAM 文件是 CCS（Circular Consensus Sequences）处理后的文件
2. `--chunk` 参数决定拆分的文件数量，建议根据数据大小和可用计算资源调整
3. 引物文件 (`--primers`) 必须提供，因为 LIMA 步骤需要
4. 如果使用 `--aligner ultra`，则必须提供 GTF 文件

### 4.3 故障排除

**错误：文件未找到**
- 检查 samplesheet 中的路径是否正确
- 确保使用绝对路径或相对于工作目录的正确路径

**错误：LIMA 失败**
- 检查引物文件格式是否正确（FASTA 格式）
- 确认 CCS BAM 文件质量良好

**性能优化**
- 增加 `--chunk` 值以提高并行度（建议：20-80）
- 根据可用内存调整 Picard 的内存设置（在 `nextflow.config` 中）

---

## 5. 技术实现详解

### 5.1 工作流程图解

```
CCS BAM 输入
    ↓
PICARD_SPLITSAMBYNUMBEROFREADS (拆分为 N 个文件)
    ↓
PICARD_FILENAME (重命名文件)
    ↓
LIMA (去除引物)
    ↓
ISOSEQ_REFINE (poly-A 过滤和去除)
    ↓
BAMTOOLS_CONVERT (转换为 FASTA)
    ↓
GSTAMA_POLYACLEANUP (清理 poly-A)
    ↓
比对 (MINIMAP2 或 ULTRA)
    ↓
TAMA 处理 (COLLAPSE 和 MERGE)
```

### 5.2 Picard 拆分与重命名

**Picard 拆分逻辑**:
输入文件会通过 Picard SplitSamByNumberOfReads 工具处理：
```bash
picard SplitSamByNumberOfReads \
  INPUT=input.ccs.bam \
  OUTPUT=. \
  OUT_PREFIX=sample_name \
  SPLIT_TO_N_FILES=40 \
  VALIDATION_STRINGENCY=SILENT
```

**Picard 拆分参数 (Groovy)**:
```groovy
PICARD_SPLITSAMBYNUMBEROFREADS(
    ch_samplesheet,              // 输入: CCS BAM 文件
    [ [:], [], [] ],             // 无需参考基因组
    Channel.value(0),            // split_to_N_reads (未使用)
    Channel.value(params.chunk), // split_to_N_files (默认: 40)
    []                           // 无参数文件
)
```

**文件重命名逻辑**:
Picard 输出格式为 `{prefix}_0001.bam`，PICARD_FILENAME 模块将其转换为 `{prefix}.chunk1.bam`，以符合后续 LIMA 流程的期望。

```bash
num=$(echo $f | sed 's/.*_0*//; s/\.bam//')
mv "$f" "${prefix}.chunk${num}.bam"
```

**Meta 信息更新**:
拆分后的每个文件都会更新 meta 信息，以便在处理过程中追踪每个 chunk，并在最后合并时识别。

```groovy
.map {
    def chk       = (it[1] =~ /.*\.(chunk\d+)\.bam/)[ 0 ][ 1 ]
    def id_former = it[0].id                              // 保存原始样本 ID
    def id_new    = it[0].id + "." + chk                  // 添加 chunk 标识
    return [ [id:id_new, id_former:id_former, single_end:true], it[1] ]
}
```

### 5.3 核心代码修改 (Workflow)

**LIMA entrypoint 逻辑 (workflows/isoseq.nf)**:

```groovy
if (params.entrypoint == "lima") {
    // Split CCS BAM files using Picard
    PICARD_SPLITSAMBYNUMBEROFREADS(...)
    
    // Rename split BAM files
    PICARD_FILENAME(...)
    
    // Update meta and flatten
    PICARD_FILENAME.out.bam.transpose().map {...}
    
    // Process through LIMA -> REFINE -> CONVERT -> POLYACLEANUP
    LIMA(...)
    ISOSEQ_REFINE(...)
    BAMTOOLS_CONVERT(...)
    GSTAMA_POLYACLEANUP(...)
}
```

---

## 6. 修改文件列表

### 1. 新增文件

**模块文件**
- `modules/local/picard/filename/main.nf`: 自定义本地模块，用于重命名 Picard 拆分后的 BAM 文件。

**配置和文档文件**
- `assets/samplesheet_lima_entrypoint.csv`: 测试用的 samplesheet 示例。
- `LIMA_ENTRYPOINT_SUMMARY_CN.md` (本文档): 功能总结与使用指南。

### 2. 修改的文件

**`nextflow_schema.json`**
- 添加了 `lima` 选项到 `entrypoint` 参数枚举中。

**`workflows/isoseq.nf`**
- 添加了模块导入 (`PICARD_FILENAME`, `PICARD_SPLITSAMBYNUMBEROFREADS`)。
- 实现了 `lima` entrypoint 的主要逻辑流程。
- 更新了 `map` entrypoint 的逻辑以兼容新流程。
- 添加了版本信息收集和 MultiQC 文件收集逻辑。

### 3. 安装的 nf-core 模块
- `picard/splitsambynumberofreads`: 用于 BAM 文件拆分。
