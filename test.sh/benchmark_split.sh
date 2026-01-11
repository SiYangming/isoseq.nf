#!/bin/bash

# 设置变量
BAM="T6-R.Iso_bc01.bcM0001.ISO.bam"
TOTAL_READS=6782894
OUT_DIR_WITH="output_with_param"
OUT_DIR_WITHOUT="output_without_param"

# 创建输出目录
mkdir -p $OUT_DIR_WITH $OUT_DIR_WITHOUT

echo "开始测试..."

# 1. 测试提供 TOTAL_READS_IN_INPUT 的情况
echo "--- 测试 1: 提供 TOTAL_READS_IN_INPUT ---"
start_time=$(date +%s)
picard SplitSamByNumberOfReads \
    INPUT=$BAM \
    OUTPUT=$OUT_DIR_WITH \
    SPLIT_TO_N_FILES=40 \
    TOTAL_READS_IN_INPUT=$TOTAL_READS \
    OUT_PREFIX=with_reads_ \
    COMPRESSION_LEVEL=5
end_time=$(date +%s)
duration_with=$((end_time - start_time))

# 2. 测试省略 TOTAL_READS_IN_INPUT 的情况
echo "--- 测试 2: 省略 TOTAL_READS_IN_INPUT ---"
start_time=$(date +%s)
picard SplitSamByNumberOfReads \
    INPUT=$BAM \
    OUTPUT=$OUT_DIR_WITHOUT \
    SPLIT_TO_N_FILES=40 \
    OUT_PREFIX=no_reads_ \
    COMPRESSION_LEVEL=5
end_time=$(date +%s)
duration_without=$((end_time - start_time))

# 输出结果对比
echo "========================================"
echo "测试结果汇总："
echo "提供参数耗时: $duration_with 秒"
echo "省略参数耗时: $duration_without 秒"
echo "节省时间比例: $(echo "scale=2; ($duration_without - $duration_with) / $duration_without * 100" | bc)%"
echo "========================================"

