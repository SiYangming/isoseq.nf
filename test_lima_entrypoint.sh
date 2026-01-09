#!/bin/bash

# LIMA Entrypoint 测试脚本
# 使用项目中的 testdata/alz.ccs.bam 进行测试

echo "==========================================="
echo "LIMA Entrypoint 测试脚本"
echo "==========================================="
echo ""

# 检查必需文件
if [ ! -f "testdata/alz.ccs.bam" ]; then
    echo "❌ 错误: 找不到测试数据文件 testdata/alz.ccs.bam"
    exit 1
fi

if [ ! -f "assets/samplesheet_lima_entrypoint.csv" ]; then
    echo "❌ 错误: 找不到 samplesheet 文件"
    exit 1
fi

echo "✅ 找到测试数据文件"
echo "✅ 找到 samplesheet 文件"
echo ""

# 显示需要提供的参数
echo "⚠️  注意: 您需要提供以下文件路径:"
echo "   --primers  : 引物序列文件 (FASTA 格式)"
echo "   --fasta    : 参考基因组序列"
echo "   --gtf      : 基因组注释 (如果使用 uLTRA 比对器)"
echo ""

# 检查是否提供了引物文件
if [ -z "$1" ]; then
    echo "使用方法:"
    echo "  $0 <primers.fasta> <genome.fasta> [genome.gtf]"
    echo ""
    echo "示例:"
    echo "  $0 primers.fasta genome.fasta"
    echo "  $0 primers.fasta genome.fasta genome.gtf  # 使用 uLTRA"
    echo ""
    echo "完整测试命令示例:"
    echo ""
    echo "nextflow run main.nf \\"
    echo "  --input assets/samplesheet_lima_entrypoint.csv \\"
    echo "  --entrypoint lima \\"
    echo "  --primers primers.fasta \\"
    echo "  --fasta genome.fasta \\"
    echo "  --outdir results_lima_test \\"
    echo "  --chunk 40 \\"
    echo "  --aligner minimap2"
    exit 1
fi

PRIMERS=$1
FASTA=$2
GTF=$3

# 检查文件是否存在
if [ ! -f "$PRIMERS" ]; then
    echo "❌ 错误: 引物文件不存在: $PRIMERS"
    exit 1
fi

if [ ! -f "$FASTA" ]; then
    echo "❌ 错误: 基因组文件不存在: $FASTA"
    exit 1
fi

echo "✅ 引物文件: $PRIMERS"
echo "✅ 基因组文件: $FASTA"

# 构建命令
CMD="nextflow run main.nf \
  --input assets/samplesheet_lima_entrypoint.csv \
  --entrypoint lima \
  --primers $PRIMERS \
  --fasta $FASTA \
  --outdir results_lima_test \
  --chunk 40"

if [ ! -z "$GTF" ]; then
    if [ ! -f "$GTF" ]; then
        echo "❌ 错误: GTF 文件不存在: $GTF"
        exit 1
    fi
    echo "✅ GTF 文件: $GTF"
    CMD="$CMD --gtf $GTF --aligner ultra"
else
    CMD="$CMD --aligner minimap2"
fi

echo ""
echo "==========================================="
echo "准备运行测试"
echo "==========================================="
echo ""
echo "命令:"
echo "$CMD"
echo ""
read -p "是否继续? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 开始运行..."
    echo ""
    eval $CMD
else
    echo "❌ 已取消"
fi
