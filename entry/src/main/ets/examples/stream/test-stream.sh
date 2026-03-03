#!/bin/bash

# ==============================================================================
# WebServer - 流式传输功能测试脚本
#
# 使用方法:
# 1. 启动流式传输示例服务器 (默认端口 8080)
# 2. 在终端中运行此脚本: ./test-stream.sh
# 3. 脚本将测试各种流式传输场景
#
# 注意: 请确保已安装 curl
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

print_header "流式传输功能测试"

# --- 1. 测试首页 ---
print_header "1. 测试首页"
echo "▶️  命令: curl ${BASE_URL}/"
echo ""
curl -s ${BASE_URL}/ | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 2. 测试流式文本数据 ---
print_header "2. 测试流式文本数据"
echo "▶️  命令: curl ${BASE_URL}/api/stream/text"
echo ""
echo "◀️  响应:"
curl -N ${BASE_URL}/api/stream/text
echo ""
echo "------------------------------------------------------------------------------"

# --- 3. 测试Server-Sent Events ---
print_header "3. 测试Server-Sent Events"
echo "▶️  命令: curl ${BASE_URL}/api/stream/events"
echo ""
echo "◀️  响应:"
timeout 10s curl -N ${BASE_URL}/api/stream/events || true
echo ""
echo "------------------------------------------------------------------------------"

# --- 4. 测试大数据流 ---
print_header "4. 测试大数据流"
echo "▶️  命令: curl ${BASE_URL}/api/stream/large"
echo ""
echo "◀️  响应: (显示前100字节和后100字节)"
response=$(curl -s ${BASE_URL}/api/stream/large)
echo "${response:0:100}..."
echo "..."
echo "${response: -100}"
echo ""
echo "总大小: ${#response} 字节"
echo ""
echo "------------------------------------------------------------------------------"

# --- 5. 测试文件流 ---
print_header "5. 测试文件流"
echo "▶️  命令: curl ${BASE_URL}/api/stream/file"
echo ""
echo "◀️  响应: (显示前200字节)"
curl -s ${BASE_URL}/api/stream/file | head -c 200
echo ""
echo "..."
echo ""
echo "------------------------------------------------------------------------------"

# --- 6. 测试实时日志流 ---
print_header "6. 测试实时日志流"
echo "▶️  命令: curl ${BASE_URL}/api/stream/logs"
echo ""
echo "◀️  响应:"
curl -N ${BASE_URL}/api/stream/logs
echo ""
echo "------------------------------------------------------------------------------"

# --- 7. 测试进度报告 ---
print_header "7. 测试进度报告"
echo "▶️  命令: curl ${BASE_URL}/api/stream/progress"
echo ""
echo "◀️  响应:"
curl -N ${BASE_URL}/api/stream/progress | while IFS= read -r line; do
  echo "$line" | jq -c .
done
echo ""
echo "------------------------------------------------------------------------------"

# --- 8. 测试分块传输编码 ---
print_header "8. 验证分块传输编码"
echo "▶️  命令: curl -v ${BASE_URL}/api/stream/text 2>&1 | grep -i 'transfer-encoding'"
echo ""
curl -v ${BASE_URL}/api/stream/text 2>&1 | grep -i 'transfer-encoding' || echo "未找到Transfer-Encoding头"
echo ""
echo "------------------------------------------------------------------------------"

print_header "测试完成!"
echo "✅ 所有流式传输测试用例执行完毕"
echo ""
