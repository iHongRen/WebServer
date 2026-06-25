#!/bin/bash

# ==============================================================================
# WebServer - 文件上传完整测试脚本
#
# 覆盖三种上传方式：
#   1. FileUpload 中间件（multipart/form-data）
#   2. 流式上传（server.stream，GB 级大文件）
#   3. 分片上传（断点续传）
#
# 使用方法:
#   1. 启动 FileUploadPage 示例服务器（默认端口 8080）
#   2. 运行: ./test-upload.sh
# ==============================================================================

HOST="192.168.2.74"
PORT="8080"
BASE_URL="http://${HOST}:${PORT}"
CHUNK_SIZE=$((1024 * 1024))  # 1MB 分片

print_header() {
  echo ""
  echo "=============================================================================="
  echo "  $1"
  echo "=============================================================================="
  echo ""
}

run_curl() {
  echo "▶️  命令: curl $*"
  echo ""
  echo "◀️  响应:"
  eval "curl -s $*" | jq .
  echo ""
  echo "------------------------------------------------------------------------------"
}

calculate_hash() {
  if command -v md5 &>/dev/null; then
    md5 -q "$1"
  else
    echo "$(date +%s)_$(basename $1)"
  fi
}

print_header "文件上传完整功能测试"

# =============================================================================
# 一、FileUpload 中间件测试（multipart/form-data）
# =============================================================================

print_header "1. 基本文件上传（multipart/form-data）"
echo "正在创建 1MB 测试文件..."
dd if=/dev/urandom of=test_basic.bin bs=1024 count=1024 2>/dev/null
run_curl "-X POST ${BASE_URL}/api/upload/basic \
  -F 'uploadFile=@test_basic.bin' \
  -F 'description=基本上传测试'"

print_header "2. 多文件上传"
dd if=/dev/urandom of=test_multi1.bin bs=1024 count=512 2>/dev/null
dd if=/dev/urandom of=test_multi2.bin bs=1024 count=512 2>/dev/null
run_curl "-X POST ${BASE_URL}/api/upload/multiple \
  -F 'file1=@test_multi1.bin' \
  -F 'file2=@test_multi2.bin'"

print_header "3. 安全文件名上传"
run_curl "-X POST ${BASE_URL}/api/upload/safe \
  -F 'file=@test_basic.bin'"

print_header "4. 限制大小上传"
run_curl "-X POST ${BASE_URL}/api/upload/limited \
  -F 'file=@test_basic.bin'"

# =============================================================================
# 二、流式上传测试（server.stream，使用 -T 避免 OOM）
# =============================================================================

print_header "5. 准备流式上传测试文件（100MB）"
STREAM_FILE="/tmp/stream_test.bin"
dd if=/dev/zero of="${STREAM_FILE}" bs=1048576 count=100 2>/dev/null
echo "✅ 已生成测试文件: ${STREAM_FILE} ($(du -sh ${STREAM_FILE} | cut -f1))"
echo ""
echo "------------------------------------------------------------------------------"

print_header "6. 流式上传 - 写入磁盘（-T 流式发送，不占用客户端内存）"
echo "▶️  命令: curl -X POST .../api/upload/stream -H 'X-File-Name: stream_test.bin' -T ..."
echo ""
echo "◀️  响应:"
curl -s -X POST "${BASE_URL}/api/upload/stream" \
     -H "Content-Type: application/octet-stream" \
     -H "X-File-Name: stream_test.bin" \
     -H "Expect:" \
     -T "${STREAM_FILE}" | jq .
echo ""
echo "------------------------------------------------------------------------------"
rm -f "${STREAM_FILE}"

# =============================================================================
# 三、分片上传测试（断点续传）
# =============================================================================

print_header "7. 创建分片上传测试文件（10MB）"
CHUNK_FILE="test_chunk.bin"
dd if=/dev/urandom of=${CHUNK_FILE} bs=1m count=10 2>/dev/null
FILE_SIZE=$(stat -f%z ${CHUNK_FILE} 2>/dev/null || stat -c%s ${CHUNK_FILE})
FILE_HASH=$(calculate_hash ${CHUNK_FILE})
TOTAL_CHUNKS=$(( (FILE_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE ))
echo "✅ 文件大小: ${FILE_SIZE} bytes，哈希: ${FILE_HASH}，总分片数: ${TOTAL_CHUNKS}"
echo "------------------------------------------------------------------------------"

print_header "8. 检查断点续传状态"
run_curl "-X POST ${BASE_URL}/api/upload/chunk/check \
  -H 'Content-Type: application/json' \
  -d '{\"fileHash\": \"${FILE_HASH}\", \"fileName\": \"${CHUNK_FILE}\"}'"

print_header "9. 分片上传"
TEMP_DIR="./temp_chunks"
mkdir -p ${TEMP_DIR}
split -b ${CHUNK_SIZE} ${CHUNK_FILE} ${TEMP_DIR}/chunk_

CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR}/chunk_*; do
  echo "上传分片 $((CHUNK_INDEX + 1))/${TOTAL_CHUNKS}..."
  curl -s -X POST ${BASE_URL}/api/upload/chunk/upload \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${TOTAL_CHUNKS}" \
    -F "fileName=${CHUNK_FILE}" \
    -F "fileHash=${FILE_HASH}" | jq .
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
done

echo "✅ 所有分片上传完成"
echo "------------------------------------------------------------------------------"

print_header "10. 查看上传任务列表"
run_curl "-X GET ${BASE_URL}/api/upload/chunk/tasks"

print_header "11. 合并分片"
run_curl "-X POST ${BASE_URL}/api/upload/chunk/merge \
  -H 'Content-Type: application/json' \
  -d '{\"fileHash\": \"${FILE_HASH}\", \"fileName\": \"${CHUNK_FILE}\"}'"

# =============================================================================
# 四、断点续传测试
# =============================================================================

print_header "12. 断点续传测试（只上传前2个分片后模拟中断）"
RESUME_FILE="test_resume.bin"
dd if=/dev/urandom of=${RESUME_FILE} bs=1m count=5 2>/dev/null
RESUME_HASH=$(calculate_hash ${RESUME_FILE})
RESUME_SIZE=$(stat -f%z ${RESUME_FILE} 2>/dev/null || stat -c%s ${RESUME_FILE})
RESUME_CHUNKS=$(( (RESUME_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE ))

TEMP_DIR2="./temp_resume"
mkdir -p ${TEMP_DIR2}
split -b ${CHUNK_SIZE} ${RESUME_FILE} ${TEMP_DIR2}/chunk_

# 只上传前2片
CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR2}/chunk_*; do
  [ ${CHUNK_INDEX} -ge 2 ] && break
  curl -s -X POST ${BASE_URL}/api/upload/chunk/upload \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${RESUME_CHUNKS}" \
    -F "fileName=${RESUME_FILE}" \
    -F "fileHash=${RESUME_HASH}" | jq .
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
done

echo "⏸  模拟中断，已上传 2/${RESUME_CHUNKS} 片"

# 查询续传状态
run_curl "-X POST ${BASE_URL}/api/upload/chunk/check \
  -H 'Content-Type: application/json' \
  -d '{\"fileHash\": \"${RESUME_HASH}\", \"fileName\": \"${RESUME_FILE}\"}'"

# 继续上传剩余分片
echo "继续上传剩余分片..."
CHUNK_INDEX=0
for chunk_file in ${TEMP_DIR2}/chunk_*; do
  if [ ${CHUNK_INDEX} -lt 2 ]; then
    CHUNK_INDEX=$((CHUNK_INDEX + 1))
    continue
  fi
  curl -s -X POST ${BASE_URL}/api/upload/chunk/upload \
    -F "chunk=@${chunk_file}" \
    -F "chunkIndex=${CHUNK_INDEX}" \
    -F "totalChunks=${RESUME_CHUNKS}" \
    -F "fileName=${RESUME_FILE}" \
    -F "fileHash=${RESUME_HASH}" | jq .
  CHUNK_INDEX=$((CHUNK_INDEX + 1))
done

run_curl "-X POST ${BASE_URL}/api/upload/chunk/merge \
  -H 'Content-Type: application/json' \
  -d '{\"fileHash\": \"${RESUME_HASH}\", \"fileName\": \"${RESUME_FILE}\"}'"

# =============================================================================
# 五、管理接口测试
# =============================================================================

print_header "13. 查看所有已上传文件"
run_curl "-X GET ${BASE_URL}/api/upload/files"

# 清理
print_header "清理测试文件"
rm -f test_basic.bin test_multi1.bin test_multi2.bin ${CHUNK_FILE} ${RESUME_FILE}
rm -rf ${TEMP_DIR} ${TEMP_DIR2}
echo "✅ 清理完成"

print_header "测试完成!"
echo "✅ 所有文件上传测试用例执行完毕"
echo ""
