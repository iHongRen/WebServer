#!/bin/bash

# ==============================================================================
# WebServer - BodyParser 中间件功能测试脚本
#
# 使用方法:
# 1. 启动 Body Parser 示例服务器 (默认端口 8082).
# 2. 在终端中运行此脚本: ./test-body-parser.sh
# 3. 脚本将向服务器发送不同类型的POST请求，并显示响应。
#
# 注意: 请确保已安装 curl 和 jq (用于格式化JSON输出)。
#       在macOS上安装jq: brew install jq
# ==============================================================================

# --- 配置 ---
# 服务器地址和端口
HOST="192.168.2.38"
PORT="8082"
BASE_URL="http://${HOST}:${PORT}"

# --- 辅助函数 ---
# 打印标题
print_header() {
  echo ""
  echo "=============================================================================="
  echo "  $1"
  echo "=============================================================================="
  echo ""
}

# 执行并打印 curl 命令
run_curl() {
  echo "▶️  命令:"
  echo "   curl $@"
  echo ""
  echo "◀️  响应:"
  # 将 -s (silent) 和 -w (write-out) 分开，以确保命令可读性
  # 使用 jq 来美化 JSON 输出
  eval "curl -s $@" | jq .
  echo ""
  echo "------------------------------------------------------------------------------"
}


# --- 测试开始 ---

print_header "BodyParser 中间件测试"

# --- 1. 测试 JSON 解析器 (/api/json) ---
print_header "1. 测试 application/json 解析"
run_curl "-X POST ${BASE_URL}/api/json \
  -H \"Content-Type: application/json\" \
  -d '{\"username\": \"cxy\", \"project\": \"WebServer\", \"stars\": 99}'"

# --- 2. 测试 URL-Encoded 解析器 (/api/urlencoded) ---
print_header "2. 测试 application/x-www-form-urlencoded 解析"
run_curl "-X POST ${BASE_URL}/api/urlencoded \
  -H \"Content-Type: application/x-www-form-urlencoded\" \
  --data-urlencode \"framework=ArkUI\" \
  --data-urlencode \"language=eTS\""

# --- 3. 测试 Multipart 解析器 (/api/multipart) ---
print_header "3. 测试 multipart/form-data 解析 (文件上传)"
# 创建一个临时文件用于上传
TEST_FILE="test-upload.txt"
echo "Hello from the test script for WebServer!" > ${TEST_FILE}
echo "创建了临时文件: ${TEST_FILE}"
echo ""
run_curl "-X POST ${BASE_URL}/api/multipart \
  -F \"description=This is a test file upload from a script\" \
  -F \"uploadFile=@${TEST_FILE}\""
# 清理临时文件
rm ${TEST_FILE}
echo "删除了临时文件: ${TEST_FILE}"
echo ""
echo "------------------------------------------------------------------------------"


# --- 4. 测试纯文本解析器 (/api/plain) ---
print_header "4. 测试 text/plain 解析"
run_curl "-X POST ${BASE_URL}/api/plain \
  -H \"Content-Type: text/plain\" \
  -d 'This is a plain text message sent to the server.'"

# --- 5. 测试自动解析器 (/api/auto) ---
print_header "5. 测试自动解析器 (/api/auto) - 使用 JSON"
run_curl "-X POST ${BASE_URL}/api/auto \
  -H \"Content-Type: application/json\" \
  -d '{\"parser\": \"auto\", \"detected\": \"json\"}'"

print_header "5. 测试自动解析器 (/api/auto) - 使用 Form"
run_curl "-X POST ${BASE_URL}/api/auto \
  -H \"Content-Type: application/x-www-form-urlencoded\" \
  -d 'parser=auto&detected=form'"


# --- 6. 获取解析结果 ---
print_header "6. 获取所有解析结果 (/api/results)"
run_curl "-X GET ${BASE_URL}/api/results?limit=5"

# --- 7. 清除解析结果 ---
print_header "7. 清除所有解析结果 (/api/results)"
run_curl "-X DELETE ${BASE_URL}/api/results"

print_header "测试完成!"
