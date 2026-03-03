#!/bin/bash

# ==============================================================================
# WebServer - 分片上传功能测试脚本
#
# 使用方法:
# 1. 启动分片上传示例服务器 (默认端口 8080)
# 2. 在终端中运行此脚本: ./test-upload.sh
# 3. 脚本将创建测试文件并进行分片上传测试
#
# 注意: 请确保已安装 curl 和 jq (用于格式化JSON输出)
#       在macOS上安装jq: brew install jq
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8080"
BASE_URL="http://${HOST}:${PORT}"

# 测试文件配置
TEST_FILE="test-large-file.bin"
FILE_SIZE_MB=10  # 测试文件大小（MB）
CHUNK_SIZE=$((1024 * 1024))  # 分片大小 1MB

# --- 辅助函数 ---
print_header() {
  echo ""
  echo "=============================================================================="
  echo "  $1"
  echo "=============================================================================="
  echo ""
}

run_curl() {
  echo "▶️  命令:"
  echo "   curl $@"
  echo ""
  echo "◀️  响应:"
  eval "curl -s $@" | jq .
  echo ""
  echo "------------------------------------------------------------------------------"
}

# 计算文件的简单哈希值（使用md5）
calculate_hash() {
  if command -v md5 &> /dev/null; then
    md5 -q "$1"
  else
    echo "$(date +%s)_$(basename $1)"
  fi
}

# --- 测试开始 ---

print_header "分片上传功能测试"

# --- 1. 创建测试文件 ---
print_header "1. 创建测试文件 (${FILE_SIZE_MB}MB)"
echo "正在创建 ${FILE_SIZE_MB}MB 的测试文件..."
dd if=/dev/urandom of=${TEST_FILE} bs=1m count=${FILE_SIZE_MB} 2>/dev/null
FILE_SIZE=$(stat -f%z ${TEST_FILE} 2>/dev/null || stat -c%s ${TEST_FILE})
echo "✅ 测试文件创建成功: ${TEST_FILE} (${FILE_SIZE} bytes)"
echo ""
echo "------------------------------------------------------------------------------"

# 计算文件哈希
FILE_HASH=$(calculate_hash ${TEST_FILE})
echo "📝 文件哈希: ${FILE_HASH}"
echo ""

# --- 2. 检查文件是否已存在 ---
print_header "2. 检查文件上传状态"
run_curl "-X POST ${BASE_URL}/api/upload/check \
  -H \"Content-Type: application/json\" \
  -d '{\"fileHash\": \"${FILE_HASH}\", \"fileName\": \"${TEST_FILE}\"}'"

# --- 3. 分片上传 ---
print_header "3. 开始分片上传"

# 计算总分片数
TOTAL_CHUNKS=$(( (FILE_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE ))
echo "📦 总分片数: ${TOTAL_CHUNKS}"
echo "📏 分片大小: ${CHUNK_SIZE} bytes"
echo ""

# 创建临时目录存放分片
TEMP_DIR="./temp_chunks"
mkdir -p ${TEMP_DIR}

# 分割文件
echo "正在分割文件..."
split -b ${CHUNK_SIZE} ${TEST_FILE} ${TEMP_DIR}/chunk_

# 上传每个分片
CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR}/chunk_*; do
  echo "上传分片 $((CHUNK_INDEX + 1))/${TOTAL_CHUNKS}..."
  
  curl -s -X POST ${BASE_URL}/api/upload/chunk \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${TOTAL_CHUNKS}" \
    -F "fileName=${TEST_FILE}" \
    -F "fileHash=${FILE_HASH}" | jq .
  
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
  echo ""
done

echo "✅ 所有分片上传完成"
echo ""
echo "------------------------------------------------------------------------------"

# --- 4. 查看上传任务 ---
print_header "4. 查看上传任务列表"
run_curl "-X GET ${BASE_URL}/api/upload/tasks"

# --- 5. 合并分片 ---
print_header "5. 合并分片"
run_curl "-X POST ${BASE_URL}/api/upload/merge \
  -H \"Content-Type: application/json\" \
  -d '{\"fileHash\": \"${FILE_HASH}\", \"fileName\": \"${TEST_FILE}\"}'"

# --- 6. 查看已上传文件 ---
print_header "6. 查看已上传文件列表"
run_curl "-X GET ${BASE_URL}/api/upload/files"

# --- 7. 测试断点续传 ---
print_header "7. 测试断点续传功能"

# 创建新的测试文件
TEST_FILE_2="test-resume.bin"
dd if=/dev/urandom of=${TEST_FILE_2} bs=1m count=5 2>/dev/null
FILE_HASH_2=$(calculate_hash ${TEST_FILE_2})
FILE_SIZE_2=$(stat -f%z ${TEST_FILE_2} 2>/dev/null || stat -c%s ${TEST_FILE_2})
TOTAL_CHUNKS_2=$(( (FILE_SIZE_2 + CHUNK_SIZE - 1) / CHUNK_SIZE ))

echo "创建测试文件: ${TEST_FILE_2}"
echo "文件哈希: ${FILE_HASH_2}"
echo "总分片数: ${TOTAL_CHUNKS_2}"
echo ""

# 分割文件
TEMP_DIR_2="./temp_chunks_2"
mkdir -p ${TEMP_DIR_2}
split -b ${CHUNK_SIZE} ${TEST_FILE_2} ${TEMP_DIR_2}/chunk_

# 只上传前两个分片
echo "上传前2个分片（模拟中断）..."
CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR_2}/chunk_*; do
  if [ ${CHUNK_INDEX} -ge 2 ]; then
    break
  fi
  
  curl -s -X POST ${BASE_URL}/api/upload/chunk \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${TOTAL_CHUNKS_2}" \
    -F "fileName=${TEST_FILE_2}" \
    -F "fileHash=${FILE_HASH_2}" | jq .
  
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
  echo ""
done

# 检查上传状态
echo "检查上传状态（应该显示已上传2个分片）..."
run_curl "-X POST ${BASE_URL}/api/upload/check \
  -H \"Content-Type: application/json\" \
  -d '{\"fileHash\": \"${FILE_HASH_2}\", \"fileName\": \"${TEST_FILE_2}\"}'"

# 继续上传剩余分片
echo "继续上传剩余分片..."
CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR_2}/chunk_*; do
  if [ ${CHUNK_INDEX} -lt 2 ]; then
    CHUNK_INDEX=$((CHUNK_INDEX + 1))
    continue
  fi
  
  curl -s -X POST ${BASE_URL}/api/upload/chunk \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${TOTAL_CHUNKS_2}" \
    -F "fileName=${TEST_FILE_2}" \
    -F "fileHash=${FILE_HASH_2}" | jq .
  
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
  echo ""
done

# 合并文件
echo "合并文件..."
run_curl "-X POST ${BASE_URL}/api/upload/merge \
  -H \"Content-Type: application/json\" \
  -d '{\"fileHash\": \"${FILE_HASH_2}\", \"fileName\": \"${TEST_FILE_2}\"}'"

# --- 8. 测试取消上传 ---
print_header "8. 测试取消上传功能"

# 创建新的测试文件
TEST_FILE_3="test-cancel.bin"
dd if=/dev/urandom of=${TEST_FILE_3} bs=1m count=3 2>/dev/null
FILE_HASH_3=$(calculate_hash ${TEST_FILE_3})
FILE_SIZE_3=$(stat -f%z ${TEST_FILE_3} 2>/dev/null || stat -c%s ${TEST_FILE_3})
TOTAL_CHUNKS_3=$(( (FILE_SIZE_3 + CHUNK_SIZE - 1) / CHUNK_SIZE ))

echo "创建测试文件: ${TEST_FILE_3}"
echo "文件哈希: ${FILE_HASH_3}"
echo ""

# 分割并上传第一个分片
TEMP_DIR_3="./temp_chunks_3"
mkdir -p ${TEMP_DIR_3}
split -b ${CHUNK_SIZE} ${TEST_FILE_3} ${TEMP_DIR_3}/chunk_

echo "上传第一个分片..."
chunk_file=$(ls ${TEMP_DIR_3}/chunk_* | head -n 1)
curl -s -X POST ${BASE_URL}/api/upload/chunk \
  -F "chunk=@${chunk_file}" \
  -F "chunkIndex=0" \
  -F "totalChunks=${TOTAL_CHUNKS_3}" \
  -F "fileName=${TEST_FILE_3}" \
  -F "fileHash=${FILE_HASH_3}" | jq .
echo ""

# 取消上传
echo "取消上传..."
run_curl "-X DELETE ${BASE_URL}/api/upload/cancel/${FILE_HASH_3}"

# 验证任务已删除
echo "验证任务已删除..."
run_curl "-X GET ${BASE_URL}/api/upload/tasks"

# --- 清理 ---
print_header "清理测试文件"
rm -f ${TEST_FILE} ${TEST_FILE_2} ${TEST_FILE_3}
rm -rf ${TEMP_DIR} ${TEMP_DIR_2} ${TEMP_DIR_3}
echo "✅ 清理完成"
echo ""

print_header "测试完成!"
echo "✅ 所有测试用例执行完毕"
echo ""
