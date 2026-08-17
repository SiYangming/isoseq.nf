#!/bin/bash
set -e

# ========== 配置参数（根据你的实际路径修改） ==========
CORR_FASTA="/data/09_GSTAMA_MERGE/T6_corrected.fasta"  # 你的校正后FASTA文件
THREADS=60                                             # 线程数（和SQANTI3保持一致）
OUTPUT_DIR="/data/T6_sqanti3/TD2"                      # TD2结果输出目录（和SQANTI3输出目录关联）
LOG_DIR="/data/T6_sqanti3/logs"                        # 日志目录

# ========== 1. 创建目录 ==========
mkdir -p ${OUTPUT_DIR}
mkdir -p ${LOG_DIR}

# ========== 2. 运行 TD2.LongOrfs（ORF搜索） ==========
echo "开始运行 TD2.LongOrfs ..."
docker run --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):/data \
  -v /data1:/data1 \
  quay.io/biocontainers/td2:1.0.7--pyhdfd78af_0 \
  TD2.LongOrfs -t ${CORR_FASTA} -O ${OUTPUT_DIR} -S --threads ${THREADS} > ${LOG_DIR}/TD2_LongOrfs.log 2>&1

# ========== 3. 运行 TD2.Predict（ORF预测） ==========
echo "开始运行 TD2.Predict ..."
docker run --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):/data \
  -v /data1:/data1 \
  quay.io/biocontainers/td2:1.0.7--pyhdfd78af_0 \
  bash -c "cd ${OUTPUT_DIR}; TD2.Predict -t ${CORR_FASTA} -O ./ " > ${LOG_DIR}/TD2_Predict.log 2>&1

# ========== 4. 输出结果路径 ==========
ORF_OUTPUT="${OUTPUT_DIR}/$(basename ${CORR_FASTA}).TD2.pep"
echo "TD2 运行完成！ORF结果文件：${ORF_OUTPUT}"
echo "ORF_OUTPUT=${ORF_OUTPUT}" > ${LOG_DIR}/td2_output.path  # 保存结果路径，供SQANTI3使用
