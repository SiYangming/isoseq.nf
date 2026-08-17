# isoseq.nf 服务器运行指南

> 参考：`/Users/siyangming/nextflow_nf_core/circdna.nf/SERVER_RUN_GUIDE.md`
> 配置文件：`isoseq.nf/conf/server.config`（FASTA 基础路径、27 个物种基因组映射、执行器资源）
> 大基因组配置：`isoseq.nf/conf/large_genome.config`
> 本地集成测试：见本文档第 6 节（原 `run_test.sh` 已合并至此处，不再单独保留）

## 1. 连接服务器

```bash
ssh <user>@<server_ip>
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
```

服务器配置：128 CPUs / 503 GB 内存（`conf/server.config` 中 `executor` 保留 96 CPUs / 400 GB 供 pipeline 使用）。

## 2. 参考基因组（服务器已就位，无需同步）

参考基因组已统一存放于服务器的 `PublicDB/reference` 目录（非旧版 `/data1/users/siyangming/FASTA`，该目录已不存在），结构与 `conf/server.config` 中的 `params.genomes{}` 完全对齐：

```text
/data1/users/siyangming/PublicDB/reference/
├── {SpeciesName}/                                  # 物种目录（拉丁学名）
│   ├── {SpeciesName}.{Build}.dna.fa.gz             # 基因组 FASTA（bgzip + .fai/.gzi）
│   ├── {SpeciesName}.{Build}.dna.toplevel.fa.gz    # 基因组 FASTA（原始 gzip）
│   ├── {SpeciesName}.{Build}.{Release}.gtf.gz      # 基因注释 GTF（部分物种）
│   └── readme.md                                   # 下载/解压/文件清单记录
├── Arabidopsis_thaliana/
│   ├── Arabidopsis_thaliana.TAIR10.dna.fa.gz
│   └── Arabidopsis_thaliana.TAIR10.63.gtf.gz
└── Oryza_sativa/
    ├── Oryza_sativa.IRGSP-1.0.dna.fa.gz
    └── Oryza_sativa.IRGSP-1.0.63.gtf.gz
```

> 服务器 `conf/server.config` 中 `params.fasta_base_path = "/data1/users/siyangming/PublicDB/reference"`，所有 `params.genomes{}` 路径都基于此拼接。

### 新增物种到 `genomes{}` 映射

当需要分析新物种时（以 `Glycine_max` 为例）：

1. 将基因组 FASTA 与 GTF 按 PublicDB 规范放入 `/data1/users/siyangming/PublicDB/reference/Glycine_max/`
2. 在 `conf/server.config` 的 `params.genomes{}` 中追加条目：

```groovy
'Glycine_max' {
    fasta   = "${params.fasta_base_path}/Glycine_max/Glycine_max.Glycine_max_v2.0.dna.fa.gz"
    gtf     = "${params.fasta_base_path}/Glycine_max/Glycine_max.Glycine_max_v2.0.63.gtf.gz"
}
```

> 无 GTF 的物种可将 `gtf` 设为 `null`，此时仅支持 minimap2 比对器（uLTRA 依赖 GTF 建索引）。

## 3. 准备 sample sheet

```bash
# 示例：拟南芥 TAIR10
cat > samplesheets/Arabidopsis_thaliana_TAIR10_isoseq.csv <<EOF
sample,bam,pbi
S1,/data1/users/siyangming/isoSeq/BAM/S1.subreads.bam,/data1/users/siyangming/isoSeq/BAM/S1.subreads.bam.pbi
S2,/data1/users/siyangming/isoSeq/BAM/S2.subreads.bam,/data1/users/siyangming/isoSeq/BAM/S2.subreads.bam.pbi
EOF
```

## 4. 按物种 / entrypoint 运行命令

### 4.1 全流程 (`entrypoint=isoseq`，从 subreads 开始)

#### 拟南芥 TAIR10（默认，基因组较小）

```bash
screen -S isoseq_Arabidopsis
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Arabidopsis_thaliana_TAIR10_isoseq.csv \
    --genome Arabidopsis_thaliana \
    --entrypoint isoseq \
    --aligner minimap2 \
    --outdir /data1/users/siyangming/isoseq_results/Arabidopsis_thaliana \
    -profile server
```

#### 水稻 IRGSP-1.0

```bash
screen -S isoseq_Oryza
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Oryza_sativa_IRGSP-1.0_isoseq.csv \
    --genome Oryza_sativa \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Oryza_sativa \
    -profile server
```

#### 小麦 IWGSC — 大基因组（使用 `server_large_genome` profile）

```bash
screen -S isoseq_Triticum
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Triticum_aestivum_IWGSC_isoseq.csv \
    --genome Triticum_aestivum \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Triticum_aestivum \
    -profile server_large_genome
```

> 大基因组也可以使用 `-profile server -c conf/large_genome.config` 叠加。

#### Medicago truncatula / 旧版 SMRT Analysis 4.0 subreads

该批 `SRR7217321` / `SRR7217322` subreads 的 BAM 头部为
`BASECALLERVERSION=4.0.0.189308`，默认 ccs 6.4 会报
`chemistry compatibility ERROR`。当前使用
`conf/pbccs_SRR7217321_2.config` 与
`conf/pbccs-chem-bundle/chemistry.xml`，将
`100-862-200 / 100-861-800 / 4.0` 映射到 `S/P2-C2/5.0`。

这是最小兼容覆盖，不会修改 BAM/PBI，也不会固定旧版 ccs。此类非 barcoded
Iso-Seq 数据应使用 `REV-Kinnex-ISO/primers.fasta`，不要使用 Kinnex
barcoded primers。两个 SRA 使用不同 sample 名，避免
`GSTAMA_FILELIST` 发生输入文件重名冲突。

```bash
screen -S isoseq_Medicago
conda activate nextflow
cd /data1/users/siyangming/FLTranslatORF/isoseq.nf/

nextflow run main.nf \
  -profile server,docker \
  -c conf/pbccs_SRR7217321_2.config \
  --input samplesheets/Medicago_truncatula.csv \
  --genome Medicago_truncatula \
  --entrypoint isoseq \
  --aligner ultra \
  --primers primers/REV-Kinnex-ISO/primers.fasta \
  --outdir /data1/users/siyangming/FLTranslatORF/flcdna_results/Medicago_truncatula
```

### 4.2 从 CCS BAM 启动 (`entrypoint=lima`)

适用于已有 CCS BAM 数据的场景：

```bash
screen -S isoseq_lima_Arabidopsis
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/isoseq.nf/
nextflow run main.nf \
    --input samplesheets/Arabidopsis_thaliana_TAIR10_lima.csv \
    --genome Arabidopsis_thaliana \
    --entrypoint lima \
    --outdir /data1/users/siyangming/isoseq_results/Arabidopsis_thaliana_lima \
    -profile server
```

### 4.3 从 refine BAM 启动 (`entrypoint=isoseq3_refine`)

```bash
nextflow run main.nf \
    --input samplesheets/Arabidopsis_thaliana_TAIR10_isoseq3_refine.csv \
    --genome Arabidopsis_thaliana \
    --entrypoint isoseq3_refine \
    --outdir /data1/users/siyangming/isoseq_results/Arabidopsis_thaliana_isoseq3_refine \
    -profile server
```

### 4.4 从 FASTQ / mapped BAM 启动 (`entrypoint=map`)

uLTRA 比对器需要 GTF（此处示例使用有 GTF 注释的拟南芥）：

```bash
nextflow run main.nf \
    --input samplesheets/Arabidopsis_thaliana_TAIR10_map.csv \
    --genome Arabidopsis_thaliana \
    --entrypoint map \
    --aligner ultra \
    --outdir /data1/users/siyangming/isoseq_results/Arabidopsis_thaliana_map \
    -profile server
```

### 4.5 通过 `--fasta` 自定义基因组

当目标物种不在 `server.config` 的 `genomes{}` 映射中时，可以直接指定 FASTA 路径：

```bash
nextflow run main.nf \
    --input samplesheets/test_online.csv \
    --fasta /data1/users/siyangming/PublicDB/reference/Custom_species/Custom_species.v1.dna.fa.gz \
    --gtf /data1/users/siyangming/PublicDB/reference/Custom_species/Custom_species.v1.63.gtf.gz \
    --entrypoint isoseq \
    --outdir /data1/users/siyangming/isoseq_results/Custom_species \
    -profile server
```

### 4.6 可用物种总表（`--genome` 可选键）

**带 GTF（支持 minimap2 + uLTRA 双比对器）**：

| `--genome` | 组装版本 |
|------------|----------|
| `Arabidopsis_thaliana` | TAIR10 |
| `Beta_vulgaris` | RefBeet-1.2.2 |
| `Cryptomeria_japonica` | 1.0（GTF 为 NCBI GCF 注释） |
| `Daucus_carota` | ASM162521v1 |
| `Dendrobium_catenatum` | v2（GTF 为 NCBI GCF 注释） |
| `Helianthus_annuus` | HanXRQr2.0-SUNRISE |
| `Lactuca_sativa` | Lsat_Salinas_v11 |
| `Medicago_truncatula` | MtrunA17r5.0_ANR |
| `Oryza_sativa` | IRGSP-1.0 |
| `Solanum_lycopersicum` | SL4.0 |
| `Trifolium_pratense` | Trpr |
| `Triticum_aestivum` | IWGSC（大基因组） |
| `Vitis_vinifera` | ASM3070453v1 |

**仅 FASTA（服务器无 GTF，仅支持 minimap2）**：

| `--genome` | 组装版本 |
|------------|----------|
| `Alopecurus_myosuroides` | v1 |
| `Amaranthus_palmeri_hap1` | hap1_v01 |
| `Amaranthus_palmeri_hap2` | hap2_v01 |
| `Artemisia_annua` | v1 |
| `Boehmeria_nivea` | v1 |
| `Camelina_sativa` | Cs（仅 GFF3 注释） |
| `Cynodon_dactylon` | ASM4686236v1 |
| `Lycium_ruthenicum` | ASM4143038v1 |
| `Nicotiana_benthamiana` | v1 |
| `Oryza_rufipogon` | OR_W1943（仅 GFF3 注释） |
| `Pinellia_ternata` | v1（仅 GFF 注释） |
| `Spirodela_polyrhiza` | v2 |
| `Tragopogon_porrifolius_hap1` | hap1.1 |
| `Tragopogon_porrifolius_hap2` | hap2.1 |

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

## 6. 运行集成测试（原 `run_test.sh`）

以下脚本在本地（macOS）执行 10 组集成测试，覆盖全部 entrypoint × 比对器组合。测试数据使用仓库自带的 `testdata/` 小数据集（不依赖服务器参考基因组），每组测试输出到 `results/`。

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run a set of Nextflow integration tests for nf-core/isoseq
# Activates the `nextflow` mamba environment before invoking nextflow

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Activate mamba environment and run Nextflow tests =="

echo "Activating mamba (zsh hook) and activating 'nextflow' environment..."
set +u
eval "$(mamba shell hook --shell zsh)"
mamba activate nextflow
set -u

if ! command -v nextflow >/dev/null 2>&1; then
  echo "❌ nextflow not found in PATH after activating environment"
  exit 1
fi

echo "nextflow: $(nextflow -version 2>&1 | head -n1)"

declare -a CMDS=(
  "nextflow run main.nf -profile docker,test_local --outdir results/test"
  "nextflow run main.nf -profile docker,test_minimap2_local --outdir results/test_minimap2"
  "nextflow run main.nf -profile docker,test_minimap2_map_entrypoint_local --outdir results/test_minimap2_map_entrypoint"
  "nextflow run main.nf -profile docker,test_ultra_map_entrypoint_local --outdir results/test_ultra_map_entrypoint"
  "nextflow run main.nf -profile docker,test_lima_entrypoint_local --outdir results/test_lima_entrypoint"
  "nextflow run main.nf -profile docker,test_ultra_lima_entrypoint_local --outdir results/test_ultra_lima_entrypoint"
  "nextflow run main.nf -profile docker,test_isoseq3_refine_entrypoint_local --outdir results/test_isoseq3_refine_entrypoint"
  "nextflow run main.nf -profile docker,test_bamtools_convert_entrypoint_local --outdir results/test_bamtools_convert_entrypoint"
  "nextflow run main.nf -profile docker,test_ultra_isoseq3_refine_entrypoint_local --outdir results/test_ultra_isoseq3_refine_entrypoint"
  "nextflow run main.nf -profile docker,test_ultra_bamtools_convert_entrypoint_local --outdir results/test_ultra_bamtools_convert_entrypoint"
)

for CMD in "${CMDS[@]}"; do
  echo ""
  echo "=========================================================="
  echo "Running: $CMD"
  echo "=========================================================="
  eval "$CMD"
  echo "Finished: $CMD"
done

echo "All requested Nextflow tests completed."
```

各测试覆盖场景：

| 测试配置 | entrypoint | aligner | 覆盖场景 |
|----------|------------|---------|----------|
| `test_local.config` | isoseq | ultra | 全流程（subreads → merge） |
| `test_minimap2_local.config` | isoseq | minimap2 | 全流程 + minimap2 |
| `test_minimap2_map_entrypoint_local.config` | map | minimap2 | FASTQ 直接比对 + minimap2 |
| `test_ultra_map_entrypoint_local.config` | map | ultra | FASTQ 直接比对 + uLTRA |
| `test_lima_entrypoint_local.config` | lima | minimap2 | 从 CCS BAM 启动 |
| `test_ultra_lima_entrypoint_local.config` | lima | ultra | 从 CCS BAM + uLTRA |
| `test_isoseq3_refine_entrypoint_local.config` | isoseq3_refine | minimap2 | 从 refine BAM 启动 |
| `test_bamtools_convert_entrypoint_local.config` | bamtools_convert | minimap2 | BAM → FASTQ |
| `test_ultra_isoseq3_refine_entrypoint_local.config` | isoseq3_refine | ultra | 从 refine BAM + uLTRA |
| `test_ultra_bamtools_convert_entrypoint_local.config` | bamtools_convert | ultra | BAM → FASTQ + uLTRA |

## 7. 常用操作

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

## 8. 注意事项

- **FASTA / GTF 路径**：参考基因组存放于 `/data1/users/siyangming/PublicDB/reference/{Species}/`（`params.fasta_base_path`），与 `conf/server.config` 中 `params.genomes{}` 的拼装保持一致；新物种需先在 PublicDB 放置数据，再在 `genomes{}` 中追加条目（见第 2 节）。
- **subreads / CCS BAM 路径**：服务器默认 BAM 基础路径为 `/data1/users/siyangming/isoSeq/BAM`（`params.bam_base_path`），可由 `--input` 直接覆盖。
- **大基因组**：`Triticum_aestivum` 等大基因组需使用 `-profile server_large_genome`（或叠加 `-c conf/large_genome.config`），否则 `MINIMAP2_ALIGN` / `ULTRA_INDEX` 会因内存不足 OOM。
- **Docker 引擎**：服务器只启用 Docker（`docker { enabled = true }`），关闭 conda / singularity；用户映射（`runOptions` / `fixOwnership`）由 `docker` profile 提供，运行时可组合 `-profile docker,server`。
- **资源竞争**：`executor.cpus = 96, memory = '400 GB'`（服务器 128 CPUs / 503 GB），保留 32 CPUs / 100 GB 给系统及其他用户；多任务并行时建议通过 `--max_cpus` / `--max_memory` 限制单任务上限。
- **插件**：`nf-schema@2.7.2` 需要 Nextflow `>=25.04.8`（已在 `manifest.nextflowVersion` 中约束）。
- **测试模式**：本地集成测试见第 6 节（`-profile docker,test_*_local`，使用 `testdata/` 小数据集，各测试配置已在 `nextflow.config` 中注册为 profile）；服务器上快速验证可用 `-profile server` 跑拟南芥小样本。
- **自定义 primers**：`--primers /path/to/primers.fasta`，仓库自带 primer 文件位于 `${projectDir}/primers/`（`params.primers_base_path`）：
  - `REV-Kinnex-ISO/primers.fasta`
  - `Kinnex-full-length-RNA/REF-primers/IsoSeq_v2_primers_12.fasta`
  - `Kinnex-full-length-RNA/MAS_adapters/MAS-Seq_Adapter_v{1,2,3}/mas{16,12,8}_primers.fasta`
- **旧 SMRT Analysis 4.0 subreads**：当 ccs 6.4 报 `chemistry compatibility ERROR` 时，使用 `-c conf/pbccs_SRR7217321_2.config`。该配置只设置 `SMRT_CHEMISTRY_BUNDLE_DIR`，映射文件为 `conf/pbccs-chem-bundle/chemistry.xml`。
- **entrypoint 选择**：
  - `isoseq`：subreads → ccs → lima → refine → collapse → merge（最完整）
  - `lima`：ccs.bam → lima → refine → collapse → merge（跳过 CCS）
  - `isoseq3_refine`：refine.bam → collapse → merge
  - `bamtools_convert`：refine.bam → fastq（仅做 BAM→FASTQ 转换）
  - `map`：long_reads.fa → align → collapse → merge（适用于 Nanopore / 直接 FASTQ 输入）

## 9. 故障排查

| 现象 | 原因 | 处理 |
|------|------|------|
| `Genome 'XXX' not found in any config files` | `--genome` 不在 `conf/server.config` 的 `genomes{}` 映射中 | 在 `params.genomes{}` 中补全条目（见第 2 节），或改用 `--fasta` 直接指定 |
| `BAM file does not exist` | sample sheet 中 BAM/PBI 路径错误 | 检查文件是否存在，使用绝对路径 |
| `OutOfMemoryError` on `MINIMAP2_ALIGN` / `ULTRA_*` | 大基因组未启用 `large_genome.config` | 使用 `-profile server_large_genome` 或添加 `-c conf/large_genome.config` |
| `Docker permission denied` | 当前用户不在 docker 组 | `sudo usermod -aG docker $USER`，重新登录 |
| `Channel.fromSamplesheet` 报错 | 旧 `nf-validation` 残留 | 确认 `nextflow.config` 中 `plugins { id 'nf-schema@2.7.2' }` |
| `chemistry compatibility ERROR: unsupported sequencing chemistry combination` | 旧 BAM 头部 basecaller 为 4.0 | 添加 `-c conf/pbccs_SRR7217321_2.config` |
| `GSTAMA_FILELIST input file name collision` | 多个 BAM 使用相同 sample 名 | 每个 BAM 使用唯一 sample 名 |
| `Could not find matching barcodes` | 非 barcoded Iso-Seq 使用了 Kinnex barcoded primers | 改用 `--primers primers/REV-Kinnex-ISO/primers.fasta` |
