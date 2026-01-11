# modules.config 配置说明

## 概述

`modules.config` 文件用于定义 Nextflow DSL2 pipeline 中每个模块的选项和发布路径配置。此文件允许您为每个 process 自定义参数、输出路径和其他运行时选项。

## 配置结构

### 全局 publishDir 配置

```groovy
publishDir = [
    path: { "${params.outdir}/${task.process.tokenize(':')[-1].tokenize('_')[0].toLowerCase()}" },
    mode: params.publish_dir_mode,
    saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
]
```

这是所有 process 的默认发布目录配置：
- **path**: 动态生成输出路径，基于 process 名称
- **mode**: 发布模式（默认为 'copy'，可以是 'symlink', 'link', 'copy', 'move'）
- **saveAs**: 过滤器，排除 `versions.yml` 文件

### 可用的配置键

每个 process 可以使用以下配置键：

| 配置键 | 描述 | 示例 |
|--------|------|------|
| `ext.args` | 附加到命令的额外参数 | `ext.args = "--isoseq --peek-guess"` |
| `ext.args2` | 第二组参数（用于多工具模块） | `ext.args2 = "--secondary-option"` |
| `ext.args3` | 第三组参数（用于多工具模块） | `ext.args3 = "--tertiary-option"` |
| `ext.prefix` | 输出文件的文件名前缀 | `ext.prefix = { "${meta.id}_flnc" }` |
| `publishDir` | 自定义输出目录配置 | 见下文详细配置 |

## Lima Entrypoint 相关配置

### PICARD_SPLITSAMBYNUMBEROFREADS

将 CCS BAM 文件拆分为多个子文件，用于并行处理。

```groovy
withName: PICARD_SPLITSAMBYNUMBEROFREADS {
    publishDir = [
        path: { "${params.outdir}/01_PICARD_SPLIT" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "VALIDATION_STRINGENCY=SILENT"
}
```

**配置说明：**
- **输出目录**: `01_PICARD_SPLIT/` - 存放拆分后的 BAM 文件
- **ext.args**: `VALIDATION_STRINGENCY=SILENT` - 忽略 BAM 文件验证警告，提高处理速度
- **功能**: 将输入的 CCS BAM 文件拆分为 `params.chunk` 个子文件（默认 40 个）

**拆分参数控制：**
- 拆分数量由 `--chunk` 参数控制（在 nextflow.config 中默认为 40）
- 拆分后文件格式：`{prefix}_0001.bam`, `{prefix}_0002.bam`, ..., `{prefix}_0040.bam`

### PICARD_FILENAME

重命名 Picard 拆分的 BAM 文件，使其符合 LIMA 输入格式要求。

```groovy
withName: PICARD_FILENAME {
    publishDir = [
        path: { "${params.outdir}/01_PICARD_RENAME" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
}
```

**配置说明：**
- **输出目录**: `01_PICARD_RENAME/` - 存放重命名后的 BAM 文件
- **功能**: 将文件名从 `{prefix}_0001.bam` 格式转换为 `{sample}.chunk1.bam` 格式
- **重命名逻辑**:
  - 输入: `sample_name_0001.bam` → 输出: `sample_name.chunk1.bam`
  - 输入: `sample_name_0040.bam` → 输出: `sample_name.chunk40.bam`

**注意事项：**
- 此模块不接受额外参数（`ext.args`）
- 重命名操作使用 `sed` 命令完成
- 输出文件放置在 `renamed/` 子目录中

## Isoseq Entrypoint 相关配置

### PBCCS

从原始 PacBio subreads 生成 Circular Consensus Sequences (CCS)。

```groovy
withName: PBCCS {
    publishDir = [
        path: { "${params.outdir}/01_PBCCS" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = " --min-rq ${params.rq}"
}
```

**配置说明：**
- **输出目录**: `01_PBCCS/`
- **ext.args**: `--min-rq` 设置最小读取质量阈值（默认 0.9）
- **相关参数**: `--rq` (nextflow.config 中配置)

## 通用处理步骤配置

### LIMA

从 CCS 中去除引物序列。

```groovy
withName: LIMA {
    publishDir = [
        path: { "${params.outdir}/02_LIMA" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "--isoseq --peek-guess"
    ext.prefix = { "${meta.id}_flnc" }
}
```

**配置说明：**
- **输出目录**: `02_LIMA/`
- **ext.args**: 
  - `--isoseq`: 使用 IsoSeq 模式
  - `--peek-guess`: 自动检测引物方向
- **ext.prefix**: 输出文件前缀为 `{sample_id}_flnc`

### ISOSEQ_REFINE

去除没有 polyA 尾的 CCS，并从其他序列中移除 polyA 尾。

```groovy
withName: ISOSEQ_REFINE {
    publishDir = [
        path: { "${params.outdir}/03_ISOSEQ_REFINE" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
}
```

**配置说明：**
- **输出目录**: `03_ISOSEQ_REFINE/`
- **功能**: 过滤和修剪 full-length non-concatemer (FLNC) 序列

### BAMTOOLS_CONVERT

将 BAM 文件转换为 FASTA 格式。

```groovy
withName: BAMTOOLS_CONVERT {
    publishDir = [
        path: { "${params.outdir}/04_BAMTOOLS_CONVERT" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "-format fasta"
}
```

**配置说明：**
- **输出目录**: `04_BAMTOOLS_CONVERT/`
- **ext.args**: `-format fasta` 指定输出格式

### GSTAMA_POLYACLEANUP

清理读段中的 polyA 尾。

```groovy
withName: GSTAMA_POLYACLEANUP {
    publishDir = [
        path: { "${params.outdir}/05_GSTAMA_POLYACLEANUP" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.prefix = { "${meta.id}_tama" }
}
```

**配置说明：**
- **输出目录**: `05_GSTAMA_POLYACLEANUP/`
- **ext.prefix**: 输出文件前缀为 `{sample_id}_tama`

## 比对器配置

### MINIMAP2_ALIGN

使用 Minimap2 进行序列比对。

```groovy
withName: MINIMAP2_ALIGN {
    publishDir = [
        path: { "${params.outdir}/06_MINIMAP2" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "-x splice:hq -uf --secondary=no -a"
}
```

**配置说明：**
- **输出目录**: `06_MINIMAP2/`
- **ext.args**:
  - `-x splice:hq`: 使用高质量剪接比对模式
  - `-uf`: 使用 forward strand
  - `--secondary=no`: 不输出次优比对
  - `-a`: 输出所有比对信息

### ULTRA_ALIGN

使用 uLTRA 进行序列比对（需要 GTF 注释）。

```groovy
withName: ULTRA_ALIGN {
    publishDir = [
        path: { "${params.outdir}/06.2_ULTRA" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "--isoseq"
}
```

**配置说明：**
- **输出目录**: `06.2_ULTRA/`
- **ext.args**: `--isoseq` - IsoSeq 数据优化模式
- **依赖**: 需要先运行 `ULTRA_INDEX` 和 `GNU_SORT`

### GUNZIP

解压 FASTA.GZ 文件（uLTRA 不支持压缩文件）。

```groovy
withName: GUNZIP {
    publishDir = [
        path: { "${params.outdir}/06.1_GUNZIP" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.prefix = { "${meta.id}_tama" }
}
```

**配置说明：**
- **输出目录**: `06.1_GUNZIP/`
- **功能**: 解压 `.fasta.gz` 文件为 `.fasta`

## TAMA 分析配置

### GSTAMA_COLLAPSE

清理基因模型，合并相似的转录本。

```groovy
if (params.capped == true) {
    withName: GSTAMA_COLLAPSE {
        publishDir = [
            path: { "${params.outdir}/07_GSTAMA_COLLAPSE" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
        ext.args = "-x capped -b BAM -a ${params.five_prime} -m ${params.splice_junction} -z ${params.three_prime}"
    }
} else {
    withName: GSTAMA_COLLAPSE {
        publishDir = [
            path: { "${params.outdir}/07_GSTAMA_COLLAPSE" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
        ext.args = "-x no_cap -b BAM -a ${params.five_prime} -m ${params.splice_junction} -z ${params.three_prime}"
    }
}
```

**配置说明：**
- **输出目录**: `07_GSTAMA_COLLAPSE/`
- **ext.args** (条件性配置):
  - `-x capped` 或 `-x no_cap`: 根据 `params.capped` 参数选择
  - `-b BAM`: 输入格式为 BAM
  - `-a ${params.five_prime}`: 5' 端容忍度（默认 100）
  - `-m ${params.splice_junction}`: 剪接位点容忍度（默认 10）
  - `-z ${params.three_prime}`: 3' 端容忍度（默认 100）

### GSTAMA_FILELIST

生成 TAMA merge 所需的文件列表。

```groovy
withName: GSTAMA_FILELIST {
    publishDir = [
        path: { "${params.outdir}/08_GSTAMA_FILELIST" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
}
```

**配置说明：**
- **输出目录**: `08_GSTAMA_FILELIST/`
- **功能**: 创建 TSV 文件，列出所有要合并的注释

### GSTAMA_MERGE

合并多个转录组，保持来源信息。

```groovy
withName: GSTAMA_MERGE {
    publishDir = [
        path: { "${params.outdir}/09_GSTAMA_MERGE" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
    ext.args = "-a ${params.five_prime} -m ${params.splice_junction} -z ${params.three_prime}"
}
```

**配置说明：**
- **输出目录**: `09_GSTAMA_MERGE/`
- **ext.args**: 使用与 COLLAPSE 相同的容忍度参数

## 工具流程配置

### SAMPLESHEET_CHECK

验证输入的 samplesheet CSV 文件格式。

```groovy
withName: SAMPLESHEET_CHECK {
    publishDir = [
        path: { "${params.outdir}/pipeline_info" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
}
```

**配置说明：**
- **输出目录**: `pipeline_info/`
- **功能**: 检查 samplesheet 格式，生成验证报告

### CUSTOM_DUMPSOFTWAREVERSIONS

收集所有工具的版本信息。

```groovy
withName: CUSTOM_DUMPSOFTWAREVERSIONS {
    publishDir = [
        path: { "${params.outdir}/multiqc" },
        mode: params.publish_dir_mode,
        saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ]
}
```

**配置说明：**
- **输出目录**: `multiqc/`
- **功能**: 汇总所有模块的软件版本，用于可重现性

## 参数优先级

配置参数的优先级顺序（从高到低）：

1. **命令行参数**: `--param value`
2. **自定义配置文件**: `-c custom.config`
3. **Profile 配置**: `-profile test,docker`
4. **modules.config**: 模块特定配置
5. **nextflow.config**: 全局默认配置

## 修改配置的最佳实践

### 1. 修改单个模块的参数

如果只需要修改某个模块的参数，建议在命令行使用：

```bash
nextflow run main.nf \
  --input samplesheet.csv \
  --entrypoint lima \
  --chunk 60  # 增加拆分数量
```

### 2. 创建自定义配置文件

对于复杂的配置更改，创建自定义配置文件：

```groovy
// custom.config
process {
    withName: PICARD_SPLITSAMBYNUMBEROFREADS {
        memory = '16.GB'
        cpus = 4
        ext.args = "VALIDATION_STRINGENCY=LENIENT"
    }
}
```

使用：
```bash
nextflow run main.nf -c custom.config --input samplesheet.csv
```

### 3. 修改 publishDir 模式

更改输出文件的发布方式：

```groovy
// custom.config
params {
    publish_dir_mode = 'symlink'  // 使用符号链接代替复制
}
```

## Lima Entrypoint 工作流程

Lima entrypoint 的完整模块调用顺序：

```
1. PICARD_SPLITSAMBYNUMBEROFREADS  → 拆分 CCS BAM 文件
   ↓ (输出: sample_name_0001.bam, ..., sample_name_0040.bam)
2. PICARD_FILENAME                 → 重命名 BAM 文件
   ↓ (输出: sample_name.chunk1.bam, ..., sample_name.chunk40.bam)
3. LIMA                            → 去除引物
   ↓
4. ISOSEQ_REFINE                   → PolyA 过滤和修剪
   ↓
5. BAMTOOLS_CONVERT                → BAM 转 FASTA
   ↓
6. GSTAMA_POLYACLEANUP             → PolyA 清理
   ↓
7. MINIMAP2_ALIGN / ULTRA_ALIGN    → 比对
   ↓
8. GSTAMA_COLLAPSE                 → 基因模型清理
   ↓
9. GSTAMA_FILELIST                 → 生成文件列表
   ↓
10. GSTAMA_MERGE                   → 合并转录组
```

## 常见问题

### Q1: 如何增加拆分文件的数量？

**A**: 修改 `--chunk` 参数：
```bash
nextflow run main.nf --entrypoint lima --chunk 80
```

### Q2: 如何更改输出目录结构？

**A**: 创建自定义配置文件修改 `publishDir` 路径：
```groovy
process {
    withName: PICARD_SPLITSAMBYNUMBEROFREADS {
        publishDir = [
            path: { "${params.outdir}/custom_split_dir" },
            mode: params.publish_dir_mode
        ]
    }
}
```

### Q3: 如何禁用某个模块的输出发布？

**A**: 设置 `publishDir` 为 `enabled: false`：
```groovy
process {
    withName: PICARD_FILENAME {
        publishDir = [
            enabled: false
        ]
    }
}
```

### Q4: 如何为 LIMA 添加额外参数？

**A**: 修改 `ext.args`：
```groovy
process {
    withName: LIMA {
        ext.args = "--isoseq --peek-guess --min-score 80"
    }
}
```

## 相关文件

- **主配置**: `nextflow.config`
- **模块配置**: `conf/modules.config`
- **测试配置**: `conf/test_lima_entrypoint.config`
- **Lima 使用指南**: `LIMA_ENTRYPOINT_USAGE.md`
- **主工作流**: `workflows/isoseq.nf`

## 参考链接

- [Nextflow DSL2 文档](https://www.nextflow.io/docs/latest/dsl2.html)
- [nf-core 模块规范](https://nf-co.re/docs/contributing/modules)
- [Picard 文档](https://broadinstitute.github.io/picard/)
- [LIMA 工具](https://github.com/pacificbiosciences/barcoding)
- [TAMA 工具](https://github.com/GenomeRIK/tama)
