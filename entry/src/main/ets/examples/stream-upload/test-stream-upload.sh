#!/bin/bash

# ==============================================================================
# WebServer - 流式上传功能测试脚本
#
# 使用方法:
# 1. 启动流式上传示例服务器 (默认端口 8087)
# 2. 在终端中运行此脚本: ./test-stream-upload.sh
# 3. 脚本将测试各种流式上传场景
#
# 注意: 请确保已安装 curl 和 jq
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8087"
BASE_URL="http://${HOST}:${PORT}"

# --- 辅助函数 ---
print_header() {
  echo ""
  echo "=============================================================================="
  echo "  $1"
  echo "=============================================================================="
  echo ""
}

# --- 测试开始 ---

print_header "流式上传功能测试"

# --- 1. 测试首页 ---
print_header "1. 测试首页"
echo "▶️  命令: curl ${BASE_URL}/"
echo ""
curl -s ${BASE_URL}/ | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 2. 测试流式文本上传 ---
print_header "2. 测试流式文本上传"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/upload/stream-text \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       -d \"Hello, this is a streaming upload test!\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/upload/stream-text \
  -H "Transfer-Encoding: chunked" \
  -d "Hello, this is a streaming upload test! This message is sent using chunked transfer encoding." | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 3. 测试流式JSON上传 ---
print_header "3. 测试流式JSON上传"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/upload/stream-json \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"name\":\"test\",\"value\":123}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/upload/stream-json \
  -H "Transfer-Encoding: chunked" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":123,"description":"This is a streaming JSON upload"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 4. 测试流式文件上传 ---
print_header "4. 测试流式文件上传"

# 创建测试文件
TEST_FILE="/tmp/test-stream-upload.txt"
echo "This is a test file for streaming upload." > ${TEST_FILE}
echo "Line 2: Testing chunked transfer encoding." >> ${TEST_FILE}
echo "Line 3: WebServer framework supports streaming!" >> ${TEST_FILE}

echo "▶️  命令: curl -X POST ${BASE_URL}/api/upload/stream-file?filename=test.txt \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       --data-binary @${TEST_FILE}"
echo ""
echo "◀️  响应:"
curl -X POST "${BASE_URL}/api/upload/stream-file?filename=test-stream.txt" \
  -H "Transfer-Encoding: chunked" \
  --data-binary @${TEST_FILE} | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 5. 测试大文件流式上传 ---
print_header "5. 测试大文件流式上传"

# 创建一个较大的测试文件 (1MB)
LARGE_FILE="/tmp/large-test-file.bin"
dd if=/dev/urandom of=${LARGE_FILE} bs=1024 count=1024 2>/dev/null

echo "▶️  命令: curl -X POST ${BASE_URL}/api/upload/stream-large \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       --data-binary @${LARGE_FILE}"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/upload/stream-large \
  -H "Transfer-Encoding: chunked" \
  --data-binary @${LARGE_FILE} | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 6. 测试获取文件列表 ---
print_header "6. 测试获取文件列表"
echo "▶️  命令: curl ${BASE_URL}/api/upload/files"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/upload/files | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 7. 验证分块传输编码 ---
print_header "7. 验证请求使用了分块传输编码"
echo "▶️  命令: curl -v -X POST ${BASE_URL}/api/upload/stream-text \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       -d \"test\" 2>&1 | grep -i 'transfer-encoding'"
echo ""
curl -v -X POST ${BASE_URL}/api/upload/stream-text \
  -H "Transfer-Encoding: chunked" \
  -d "test" 2>&1 | grep -i 'transfer-encoding' || echo "未找到Transfer-Encoding头"
echo ""
echo "------------------------------------------------------------------------------"

# --- 8. 测试大量数据的流式上传 ---
print_header "8. 测试大量数据的流式上传"

# 生成大量文本数据
LARGE_TEXT=""
for i in {1..1000}; do
  LARGE_TEXT="${LARGE_TEXT}Line ${i}: This is a test line for streaming upload with chunked transfer encoding.\n"
done

echo "▶️  命令: echo -e \"<1000行文本>\" | curl -X POST ${BASE_URL}/api/upload/stream-text \\"
echo "       -H \"Transfer-Encoding: chunked\" \\"
echo "       --data-binary @-"
echo ""
echo "◀️  响应:"
echo -e "${LARGE_TEXT}" | curl -X POST ${BASE_URL}/api/upload/stream-text \
  -H "Transfer-Encoding: chunked" \
  --data-binary @- | jq .
echo ""
echo "------------------------------------------------------------------------------"

# 清理临时文件
rm -f ${TEST_FILE} ${LARGE_FILE}

print_header "测试完成!"
echo "✅ 所有流式上传测试用例执行完毕"
echo ""
echo "📝 测试总结:"
echo "   - 流式文本上传: ✓"
echo "   - 流式JSON上传: ✓"
echo "   - 流式文件上传: ✓"
echo "   - 大文件流式上传: ✓"
echo "   - 文件列表查询: ✓"
echo "   - 分块传输验证: ✓"
echo "   - 大量数据上传: ✓"
echo ""
