#!/bin/bash

# ==============================================================================
# WebServer - Event事件系统测试脚本
#
# 使用方法:
# 1. 启动Event示例服务器 (默认端口 8084)
# 2. 在终端中运行此脚本: ./test-event-api.sh
# 3. 脚本将测试各种事件系统功能
#
# 注意: 请确保已安装 curl 和 jq
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8084"
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

print_header "Event事件系统测试"

# --- 1. 测试服务器状态 ---
print_header "1. 测试服务器状态"
echo "▶️  命令: curl ${BASE_URL}/"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/ | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 2. 获取详细状态信息 ---
print_header "2. 获取详细状态信息"
echo "▶️  命令: curl ${BASE_URL}/status"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/status | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 3. 触发错误事件 ---
print_header "3. 触发错误事件"
echo "▶️  命令: curl ${BASE_URL}/error"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/error | jq . || echo "预期的错误响应"
echo ""
echo "💡 提示: 检查服务器控制台日志，应该能看到错误事件被捕获"
echo "------------------------------------------------------------------------------"

# --- 4. 建立多个连接以测试CLIENT_CONNECTED事件 ---
print_header "4. 建立多个连接测试"
echo "发送5个并发请求以触发CLIENT_CONNECTED事件..."
for i in {1..5}; do
  curl -s ${BASE_URL}/ > /dev/null &
done
wait
echo "✅ 5个请求已完成"
echo ""
echo "💡 提示: 检查服务器控制台日志，应该能看到CLIENT_CONNECTED事件"
echo "------------------------------------------------------------------------------"

# --- 5. 获取当前客户端列表 ---
print_header "5. 获取当前客户端列表"
echo "▶️  命令: curl ${BASE_URL}/status"
echo ""
echo "◀️  响应:"
RESPONSE=$(curl -s ${BASE_URL}/status)
echo $RESPONSE | jq .
echo ""

# 提取客户端数量
CLIENT_COUNT=$(echo $RESPONSE | jq -r '.clientCount')
echo "📊 当前客户端数量: $CLIENT_COUNT"
echo "------------------------------------------------------------------------------"

# --- 6. 测试断开客户端连接 ---
print_header "6. 测试断开客户端连接"

# 获取第一个客户端ID
FIRST_CLIENT=$(echo $RESPONSE | jq -r '.clients[0]')

if [ "$FIRST_CLIENT" != "null" ] && [ -n "$FIRST_CLIENT" ]; then
  echo "▶️  命令: curl -X POST ${BASE_URL}/disconnect/${FIRST_CLIENT}"
  echo ""
  echo "◀️  响应:"
  curl -X POST ${BASE_URL}/disconnect/${FIRST_CLIENT} | jq .
  echo ""
  echo "💡 提示: 检查服务器控制台日志，应该能看到CLIENT_DISCONNECTED事件"
else
  echo "⚠️  没有活动的客户端连接"
fi
echo "------------------------------------------------------------------------------"

# --- 7. 验证客户端断开后的状态 ---
print_header "7. 验证客户端断开后的状态"
echo "▶️  命令: curl ${BASE_URL}/status"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/status | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 8. 压力测试 - 快速连接和断开 ---
print_header "8. 压力测试 - 快速连接和断开"
echo "发送20个快速请求..."
start_time=$(date +%s%N)

for i in {1..20}; do
  curl -s ${BASE_URL}/ > /dev/null &
done
wait

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "✅ 20个请求完成，耗时: ${duration}ms"
echo ""
echo "💡 提示: 检查服务器控制台日志，应该能看到多个连接和断开事件"
echo "------------------------------------------------------------------------------"

# --- 9. 测试错误处理的健壮性 ---
print_header "9. 测试错误处理的健壮性"
echo "连续触发5次错误..."
for i in {1..5}; do
  echo "  触发错误 $i/5"
  curl -s ${BASE_URL}/error > /dev/null
  sleep 0.2
done
echo ""
echo "✅ 错误测试完成"
echo "💡 提示: 服务器应该仍然正常运行，检查错误日志"
echo "------------------------------------------------------------------------------"

# --- 10. 验证服务器仍然正常运行 ---
print_header "10. 验证服务器仍然正常运行"
echo "▶️  命令: curl ${BASE_URL}/status"
echo ""
echo "◀️  响应:"
FINAL_STATUS=$(curl -s ${BASE_URL}/status)
echo $FINAL_STATUS | jq .
echo ""

STATUS=$(echo $FINAL_STATUS | jq -r '.status')
if [ "$STATUS" = "running" ]; then
  echo "✅ 服务器运行正常"
else
  echo "⚠️  服务器状态异常"
fi
echo "------------------------------------------------------------------------------"

# --- 11. 测试无效的客户端ID ---
print_header "11. 测试无效的客户端ID"
echo "▶️  命令: curl -X POST ${BASE_URL}/disconnect/99999"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/disconnect/99999 | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 12. 长连接测试 ---
print_header "12. 长连接测试"
echo "建立长连接并保持5秒..."
curl -s ${BASE_URL}/ &
CURL_PID=$!
echo "连接PID: $CURL_PID"
sleep 5
echo "关闭连接..."
kill $CURL_PID 2>/dev/null
wait $CURL_PID 2>/dev/null
echo "✅ 长连接测试完成"
echo "💡 提示: 检查服务器日志中的连接和断开事件"
echo "------------------------------------------------------------------------------"

print_header "测试完成!"
echo "✅ 所有Event事件系统测试用例执行完毕"
echo ""
echo "📝 测试总结:"
echo "   - 服务器状态查询: ✓"
echo "   - 错误事件触发: ✓"
echo "   - 客户端连接事件: ✓"
echo "   - 客户端断开事件: ✓"
echo "   - 压力测试: ✓"
echo "   - 错误处理健壮性: ✓"
echo "   - 长连接测试: ✓"
echo ""
echo "💡 建议: 查看服务器控制台日志以验证所有事件都被正确触发和处理"
echo ""
