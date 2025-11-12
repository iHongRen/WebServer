#!/bin/bash

# ==============================================================================
# WebServer - CORS (跨域资源共享) 中间件功能测试脚本
#
# 使用方法:
# 1. 启动 CORS 示例服务器 (默认端口 8083).
# 2. 在终端中运行此脚本: ./test-cors.sh
# 3. 脚本将模拟来自不同源的、不同类型的跨域请求，并显示详细的响应头。
#
# 注意: 请确保已安装 curl。-v 选项用于显示详细的请求和响应头信息。
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8083"
BASE_URL="http://${HOST}:${PORT}"

# 允许的源 (当服务器配置为 '允许所有' 时，这个源会被接受)
ALLOWED_ORIGIN="http://example.com"
# 拒绝的源 (这个源不应被接受，除非服务器配置为 '*')
DISALLOWED_ORIGIN="http://disallowed-origin.com"

# --- 辅助函数 ---
print_header() {
  echo ""
  echo "=============================================================================="
  echo "  $1"
  echo "=============================================================================="
  echo ""
}

# 执行并打印 curl 命令 (使用 -v 显示详细信息)
run_curl() {
  echo "▶️  命令: curl $@"
  echo ""
  echo "◀️  响应 (详细模式):"
  eval "curl $@"
  echo ""
  echo "------------------------------------------------------------------------------"
}

# --- 测试开始 ---

print_header "CORS 中间件测试 (服务器应配置为允许所有源 '*' )"

# --- 1. 简单请求 (Simple Request) ---
print_header "1. 测试简单请求 (GET from ${ALLOWED_ORIGIN})"
echo "这是一个简单的GET请求，不需要预检。"
echo "预期: 响应头包含 'Access-Control-Allow-Origin: *'"
echo ""
run_curl "-X GET ${BASE_URL}/api/cors/simple -H \"Origin: ${ALLOWED_ORIGIN}\" -v"


# --- 2. 预检请求 (Preflight Request) ---
print_header "2. 测试预检请求 (POST with custom headers from ${ALLOWED_ORIGIN})"
echo "此请求包含自定义头和JSON内容，会触发一个 OPTIONS 预检请求。"

echo "--- 步骤 2a: 模拟浏览器的 OPTIONS 预检请求 ---"
echo "预期: 响应头包含 'Access-Control-Allow-Origin', 'Access-Control-Allow-Methods', 'Access-Control-Allow-Headers'"
echo ""
run_curl "-X OPTIONS ${BASE_URL}/api/cors/preflight \
  -H \"Origin: ${ALLOWED_ORIGIN}\" \
  -H \"Access-Control-Request-Method: POST\" \
  -H \"Access-Control-Request-Headers: Content-Type,X-Custom-Header\" \
  -v"

echo "--- 步骤 2b: 模拟预检通过后的实际 POST 请求 ---"
echo "预期: 请求成功，并返回JSON数据。"
echo ""
run_curl "-X POST ${BASE_URL}/api/cors/preflight \
  -H \"Origin: ${ALLOWED_ORIGIN}\" \
  -H \"Content-Type: application/json\" \
  -H \"X-Custom-Header: WebServerTest\" \
  -d '{\"message\": \"preflight test\"}'"


# --- 3. 带凭证的请求 (Credentialed Request) ---
print_header "3. 测试带凭证的请求 (POST with credentials)"
echo "带凭证的请求要求服务器在响应头中返回 'Access-Control-Allow-Credentials: true'。"
echo "注意: 当允许凭证时, 'Access-Control-Allow-Origin' 不能是 '*'，必须是具体的源。"
echo "本示例服务器的CORS配置会动态处理这个问题。"
echo ""
run_curl "-X POST ${BASE_URL}/api/cors/credentials \
  -H \"Origin: ${ALLOWED_ORIGIN}\" \
  --cookie \"session=12345\" \
  -v"


# --- 4. 测试来源被拒绝 (如果服务器配置为特定源) ---
print_header "4. 测试被拒绝的源 (GET from ${DISALLOWED_ORIGIN})"
echo "如果服务器没有配置为允许所有源 ('*')，此请求将被浏览器阻止。"
echo "预期: 响应头中 *不应* 包含 'Access-Control-Allow-Origin'。"
echo "      (注意: 服务器可能仍会处理请求，但浏览器会因缺少CORS头而阻止前端脚本访问响应)"
echo ""
run_curl "-X GET ${BASE_URL}/api/cors/simple -H \"Origin: ${DISALLOWED_ORIGIN}\" -v"


# --- 5. 获取服务器CORS配置 ---
print_header "5. 获取服务器当前的CORS配置"
run_curl "-X GET ${BASE_URL}/api/cors/config"


print_header "测试完成!"
echo "请检查上面每个请求的 'Access-Control-*' 响应头来验证CORS策略是否正确应用。"
