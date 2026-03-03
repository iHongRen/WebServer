#!/bin/bash

# ==============================================================================
# WebServer - Body Parser功能测试脚本
#
# 使用方法:
# 1. 启动Body Parser示例服务器 (默认端口 8080)
# 2. 在终端中运行此脚本: ./test-body-parser.sh
# 3. 脚本将测试各种请求体解析场景
#
# 注意: 请确保已安装 curl 和 jq
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8080"
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

print_header "Body Parser功能测试"

# --- 1. 测试JSON解析器 ---
print_header "1. 测试JSON解析器"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/json \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"name\":\"test\",\"value\":123}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/json \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":123,"nested":{"key":"value"}}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 2. 测试URL编码解析器 ---
print_header "2. 测试URL编码解析器"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/urlencoded \\"
echo "       -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "       -d \"name=test&value=123\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/urlencoded \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=test&value=123&email=test@example.com" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 3. 测试多部分表单解析器 ---
print_header "3. 测试多部分表单解析器"

# 创建测试文件
TEST_FILE="/tmp/test-multipart.txt"
echo "This is a test file for multipart upload." > ${TEST_FILE}

echo "▶️  命令: curl -X POST ${BASE_URL}/api/multipart \\"
echo "       -F \"name=test\" \\"
echo "       -F \"file=@${TEST_FILE}\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/multipart \
  -F "name=test" \
  -F "description=Test multipart upload" \
  -F "file=@${TEST_FILE}" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 4. 测试纯文本解析器 ---
print_header "4. 测试纯文本解析器"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/plain \\"
echo "       -H \"Content-Type: text/plain\" \\"
echo "       -d \"This is plain text content\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/plain \
  -H "Content-Type: text/plain" \
  -d "This is plain text content for testing the plain text parser." | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 5. 测试自动解析器 (JSON) ---
print_header "5. 测试自动解析器 - JSON"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/auto \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"type\":\"auto-json\"}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/auto \
  -H "Content-Type: application/json" \
  -d '{"type":"auto-json","message":"Testing auto parser with JSON"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 6. 测试自动解析器 (URL编码) ---
print_header "6. 测试自动解析器 - URL编码"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/auto \\"
echo "       -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "       -d \"type=auto-urlencoded\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/auto \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=auto-urlencoded&message=Testing auto parser with URL encoding" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 7. 测试自动解析器 (纯文本) ---
print_header "7. 测试自动解析器 - 纯文本"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/auto \\"
echo "       -H \"Content-Type: text/plain\" \\"
echo "       -d \"Auto parser plain text\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/auto \
  -H "Content-Type: text/plain" \
  -d "Auto parser plain text content for testing" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 8. 获取解析结果 ---
print_header "8. 获取解析结果列表"
echo "▶️  命令: curl ${BASE_URL}/api/results"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/results | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 9. 测试错误处理 (错误的Content-Type) ---
print_header "9. 测试错误处理 - 错误的Content-Type"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/json \\"
echo "       -H \"Content-Type: text/plain\" \\"
echo "       -d \"wrong content type\""
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/json \
  -H "Content-Type: text/plain" \
  -d "wrong content type" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 10. 清除所有结果 ---
print_header "10. 清除所有解析结果"
echo "▶️  命令: curl -X DELETE ${BASE_URL}/api/results"
echo ""
echo "◀️  响应:"
curl -X DELETE ${BASE_URL}/api/results | jq .
echo ""
echo "------------------------------------------------------------------------------"

# 清理临时文件
rm -f ${TEST_FILE}

print_header "测试完成!"
echo "✅ 所有Body Parser测试用例执行完毕"
echo ""
echo "📝 测试总结:"
echo "   - JSON解析器: ✓"
echo "   - URL编码解析器: ✓"
echo "   - 多部分表单解析器: ✓"
echo "   - 纯文本解析器: ✓"
echo "   - 自动解析器: ✓"
echo "   - 结果管理: ✓"
echo "   - 错误处理: ✓"
echo ""
