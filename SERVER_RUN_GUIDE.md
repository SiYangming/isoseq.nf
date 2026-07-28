# isoseq.nf 服务器运行指南

> 参考：`/Users/siyangming/nextflow_nf_core/circdna.nf/SERVER_RUN_GUIDE.md`
> 配置文件：`isoseq.nf/conf/server.config`（包含 FASTA 基础路径、9 个物种基因组映射、执行器资源）
> 大基因组配置：`isoseq.nf/conf/large_genome.config`

## 1. 连接服务器

```bash
ssh <user>@<server_ip>
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
```

服务器配置：128 CPUs / 503 GB 内存（`conf/server.config` 中 `executor` 保留 96 CPUs / 400 GB 供 pipeline 使用）。

## 2. 同步 FASTA / GTF / 注释文件到服务器

```bash
# FASTA / GTF 同步（按需修改 species 列表）
rsync -avz --progress /Users/siyangming/nextflow_nf_core/FASTA/*.fa.gz \
    <user>@<server_ip>:/data1/users/siyangming/FASTA/

# 目录结构（与 igenomes 风格保持一致）
# /data1/users/siyangming/FASTA/
# ├── Homo_sapiens/
# │   ├── NCBI/GRCh38/Sequence/WholeGenomeFasta/genome.fa
# │   ├── NCBI/GRCh38/Annotation/Genes/genes.gtf
# │   ├── Ensembl/GRCh37/...
# │   └── UCSC/hg38/...  / hg19/...
# ├── Mus_musculus/UCSC/mm10/...
# ├── Arabidopsis_thaliana/Ensembl/TAIR10/...
# ├── Oryza_sativa_japonica/Ensembl/IRGSP-1.0/...
# └── Sus_scrofa/
#     ├── Ensembl/Sscrofa10.2/...
#     └── UCSC/susScr3/...
```

> 服务器 `conf/server.config` 中 `params.fasta_base_path = "/data1/users/siyangming/FASTA"`，所有 `params.genomes{}` 路径都基于此拼接。

## 3. 准备 sample sheet

```bash
# 示例：Homo_sapiens GRCh38
cat > samplesheets/Homo_sapiens_GRCh38_isoseq.csv <<EOF
sample,bam,pbi
S1,/data1/users/siyangming/isoSeq/BAM/S1.subreads.bam,/data1/users/siyangming/isoSeq/BAM/S1.subreads.bam.pbi
S2,/data1/users/siyangming/isoSeq/BAM/S2.subreads.bam,/data1/users/siyangming/isoSeq/BAM/S2.subreads.bam.pbi
EOF
```

## 4. 按物种 / entrypoint 运行命令

### 4.1 全流程 (`entrypoint=isoseq`，从 subreads 开始)

#### 人 GRCh38

```bash
screen -S isoseq_Homo_GRCh38
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Homo_sapiens_GRCh38_isoseq.csv \
    --genome GRCh38 \
    --entrypoint isoseq \
    --aligner minimap2 \
    --outdir /data1/users/siyangming/isoseq_results/Homo_sapiens_GRCh38 \
    -profile server
```

#### 人 hg38（UCSC 版本）

```bash
screen -S isoseq_Homo_hg38
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Homo_sapiens_hg38_isoseq.csv \
    --genome hg38 \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Homo_sapiens_hg38 \
    -profile server
```

#### 拟南芥 TAIR10

```bash
screen -S isoseq_Arabidopsis
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Arabidopsis_thaliana_TAIR10_isoseq.csv \
    --genome TAIR10 \
    --entrypoint isoseq \
    --aligner minimap2 \
    --outdir /data1/users/siyangming/isoseq_results/Arabidopsis_thaliana_TAIR10 \
    -profile server
```

#### 水稻 IRGSP-1.0

```bash
screen -S isoseq_Oryza
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Oryza_sativa_IRGSP-1.0_isoseq.csv \
    --genome IRGSP-1.0 \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Oryza_sativa_IRGSP-1.0 \
    -profile server
```

#### 猪 Sscrofa10.2 — 大基因组

```bash
screen -S isoseq_Sus_scrofa
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Sus_scrofa_Sscrofa10.2_isoseq.csv \
    --genome Sscrofa10.2 \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Sus_scrofa_Sscrofa10.2 \
    -profile server \
    -c conf/large_genome.config
```

#### 猪 susScr3（UCSC 版本）— 大基因组

```bash
screen -S isoseq_Sus_susScr3
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Sus_scrofa_susScr3_isoseq.csv \
    --genome susScr3 \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Sus_scrofa_susScr3 \
    -profile server \
    -c conf/large_genome.config
```

### 4.2 从 CCS BAM 启动 (`entrypoint=lima`)

适用于已有 CCS BAM 数据的场景：

```bash
screen -S isoseq_lima_GRCh38
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Homo_sapiens_GRCh38_lima.csv \
    --genome GRCh38 \
    --entrypoint lima \
    --outdir /data1/users/siyangming/isoseq_results/Homo_sapiens_GRCh38_lima \
    -profile server
```

### 4.3 从 refine BAM 启动 (`entrypoint=isoseq3_refine`)

```bash
nextflow run main.nf \
    --input samplesheets/Homo_sapiens_GRCh38_isoseq3_refine.csv \
    --genome GRCh38 \
    --entrypoint isoseq3_refine \
    --outdir /data1/users/siyangming/isoseq_results/Homo_sapiens_GRCh38_isoseq3_refine \
    -profile server
```

### 4.4 从 FASTQ / mapped BAM 启动 (`entrypoint=map`)

```bash
nextflow run main.nf \
    --input samplesheets/Homo_sapiens_GRCh38_map.csv \
    --genome GRCh38 \
    --entrypoint map \
    --aligner ultra \
    --outdir /data1/users/siyangming/isoseq_results/Homo_sapiens_GRCh38_map \
    -profile server
```

### 4.5 通过 `--fasta` 自定义基因组

当目标物种不在 `server.config` 的 `genomes{}` 映射中时，可以直接指定 FASTA 路径：

```bash
nextflow run main.nf \
    --input samplesheets/samplesheet.csv \
    --fasta /data1/users/siyangming/FASTA/Custom_species/genome.fa \
    --gtf /data1/users/siyangming/FASTA/Custom_species/genes.gtf \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Custom_species \
    -profile server
```

## 5. 恢复 / 续跑

```bash
screen -S isoseq_<species>
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/<species>_isoseq.csv \
    --genome <species> \
    --outdir /data1/users/siyangming/isoseq_results/<species> \
    -profile server \
    -resume
```

## 6. 常用操作

```bash
# 查看所有 screen 会话
screen -ls

# 恢复某个会话
screen -r <session_name>

# 退出 screen（保持后台运行）
# Ctrl+A, then D

# 实时查看运行日志
tail -f /data1/users/siyangming/isoseq_results/<species>/reports/trace.txt

# 清理 work 目录（任务完成后可释放磁盘）
rm -rf /data1/users/siyangming/isoseq_results/<species>/work
```

## 7. 注意事项

- **FASTA / GTF 路径**：参考基因组需已上传到 `/data1/users/siyangming/FASTA/<Species>/<Source>/<Assembly>/Sequence/WholeGenomeFasta/genome.fa`，结构与 `conf/server.config` 中 `params.genomes{}` 的拼装保持一致。
- **subreads / CCS BAM 路径**：服务器默认 BAM 基础路径为 `/data1/users/siyangming/isoSeq/BAM`（`params.bam_base_path`），可由 `--input` 直接覆盖。
- **大基因组**：`susScr3` / `Sscrofa10.2` / `Triticum_aestivum` 等需要叠加 `-c conf/large_genome.config`，否则 `MINIMAP2_ALIGN` / `ULTRA_INDEX` 会因内存不足 OOM。
- **Docker 引擎**：服务器只启用 Docker（`docker { enabled = true; fixOwnership = true }`），关闭 conda / singularity。
- **资源竞争**：`executor.cpus = 96, memory = '400 GB'`（服务器 128 CPUs / 503 GB），保留 32 CPUs / 100 GB 给系统及其他用户；多任务并行时建议通过 `--max_cpus` / `--max_memory` 限制单任务上限。
- **插件**：`nf-schema@2.5.1` 需要 Nextflow `>=25.04.8`（已在 `manifest.nextflowVersion` 中约束）。
- **测试模式**：本地快速测试用 `-profile test_local`（输入 `samplesheets/samplesheet_local.csv`），仅消耗 2 CPUs / 6 GB。
- **自定义 primers**：`--primers /path/to/primers.fasta`，默认路径 `/data1/users/siyangming/isoSeq/primers/`（`params.primers_base_path`）。
- **entrypoint 选择**：
  - `isoseq`：subreads → ccs → lima → refine → collapse → merge（最完整）
  - `lima`：ccs.bam → lima → refine → collapse → merge（跳过 CCS）
  - `isoseq3_refine`：refine.bam → collapse → merge
  - `bamtools_convert`：refine.bam → fastq（仅做 BAM→FASTQ 转换）
  - `map`：long_reads.fa → align → collapse → merge（适用于 Nanopore / 直接 FASTQ 输入）

## 8. 故障排查

| 现象 | 原因 | 处理 |
|------|------|------|
| `Genome 'XXX' not found in any config files` | `--genome` 不在 `conf/server.config` 或 `conf/igenomes.config` | 在 `params.genomes{}` 中补全条目，或改用 `--fasta` 直接指定 |
| `BAM file does not exist` | sample sheet 中 BAM/PBI 路径错误 | 检查文件是否存在，使用绝对路径 |
| `OutOfMemoryError` on `MINIMAP2_ALIGN` / `ULTRA_*` | 大基因组未启用 `large_genome.config` | 添加 `-c conf/large_genome.config` |
| `Docker permission denied` | 当前用户不在 docker 组 | `sudo usermod -aG docker $USER`，重新登录 |
| `Channel.fromSamplesheet` 报错 | 旧 `nf-validation` 残留 | 确认 `nextflow.config` 中 `plugins { id 'nf-schema@2.5.1' }` |
