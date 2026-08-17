#!/usr/bin/env bash
set -euo pipefail

# Run T6 dataset (Oryza sativa long-read) with nf-core/isoseq server profile
# Activates the `nextflow` mamba environment before invoking nextflow
#
# T6 数据集个性化参数通过命令行指定；基因组（fasta/gtf）由 server.config 的
# --genome Oryza_sativa map 解析。配置参考 isoseq.nf/conf/server.config。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Activate mamba environment and run Nextflow tests =="

mamba_hook_shell="bash"
echo "Activating mamba ($mamba_hook_shell hook) and activating 'nextflow' environment..."
set +u
eval "$(mamba shell hook --shell zsh)"
mamba activate nextflow
set -u

if ! command -v nextflow >/dev/null 2>&1; then
  echo "❌ nextflow not found in PATH after activating environment"
  exit 1
fi

echo "nextflow: $(nextflow -version 2>&1 | head -n1)"

# 路径约定：在服务器上运行时，PIPELINE_DIR 默认指向 isoseq.nf 仓库
PIPELINE_DIR="${PIPELINE_DIR:-/data1/users/siyangming/nextflow_nf_core/isoseq.nf}"
OUTDIR="${OUTDIR:-/data1/users/siyangming/osa_Japonica_long_read/T6/results_T6}"

declare -a CMDS=(
  "nextflow run ${PIPELINE_DIR}/main.nf -profile server,docker \
      --genome Oryza_sativa \
      --input ${PIPELINE_DIR}/samplesheets/T6.csv \
      --outdir ${OUTDIR} \
      --primers ${PIPELINE_DIR}/primers/Kinnex-full-length-RNA/REF-primers/IsoSeq_v2_primers_12.fasta \
      --aligner ultra --entrypoint isoseq3_refine \
      --chunk 40 --five_prime 100 --splice_junction 10 --three_prime 100 --capped false"
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
