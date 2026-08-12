#!/bin/bash

export _JAVA_OPTIONS="-Xmx500g -Xms200g"  # -Xms为初始内存，提升性能
BAM="T6-R.Iso_bc01.bcM0001.ISO.bam"
TOTAL_READS=6782894
PICARD_JAR="picard"

# 清理之前的输出
rm -rf test_out_*

run_picard() {
    local mode=$1 # "with" or "without"
    local run_id=$2
    local out_dir="test_out_${mode}_${run_id}"
    mkdir -p $out_dir

    start=$(date +%s%N)
    if [ "$mode" == "with" ]; then
        java -jar $PICARD_JAR SplitSamByNumberOfReads INPUT=$BAM OUTPUT=$out_dir \
            SPLIT_TO_N_FILES=40 TOTAL_READS_IN_INPUT=$TOTAL_READS \
            OUT_PREFIX=with_ COMPRESSION_LEVEL=1 > /dev/null 2>&1
    else
        picard SplitSamByNumberOfReads INPUT=$BAM OUTPUT=$out_dir \
            SPLIT_TO_N_FILES=40 \
            OUT_PREFIX=no_ OUT_LEVEL=1 > /dev/null 2>&1
    fi
    end=$(date +%s%N)
    
    # 计算毫秒
    echo " $(( (end - start) / 1000000 ))"
}

echo "正在进行交替压力测试（排除缓存干扰）..."
echo "--------------------------------------"

# 第一轮：先跑“无参数”，此时文件可能不在缓存
echo -n "Round 1 - [无参数] (冷启动预测):"
run_picard "without" 1

# 第二轮：再跑“有参数”，此时文件已在缓存
echo -n "Round 2 - [有参数] (热缓存预测):"
run_picard "with" 2

# 第三轮：再跑“有参数”
echo -n "Round 3 - [有参数] (热缓存):    "
run_picard "with" 3

# 第四轮：再跑“无参数”
echo -n "Round 4 - [无参数] (热缓存):    "
run_picard "without" 4

echo "--------------------------------------"
echo "结果分析提示："
echo "如果 Round 1 明显慢于其他轮次，说明由于 5.9G 文件被加载进 RAM，后续运行都享受了缓存红利。"
echo "如果在全是热缓存的情况下（Round 3 vs 4），两者差异极小，说明对于 6.7M 数据，Picard 自行计数的开销可以忽略不计。"
unset _JAVA_OPTIONS#运行完成恢复原来
