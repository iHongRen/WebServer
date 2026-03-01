#!/bin/bash

# ==============================================================================
# WebServer - Logger功能测试脚本
#
# 使用方法:
# 1. 启动Logger示例服务器 (默认端口 8085)
# 2. 在终端中运行此脚本: ./test-logger-api.sh
# 3. 脚本将测试各种日志记录场景
#
# 注意: 请确保已安装 curl 和 jq
# ==============================================================================

# --- 配置 ---
HOST="192.168.2.38"
PORT="8085"
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

print_header "Logger功能测试"

# --- 1. 测试debug级别日志 ---
print_header "1. 测试debug级别日志"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/logs/test/debug \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"message\":\"Debug test\"}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/logs/test/debug \
  -H "Content-Type: application/json" \
  -d '{"message":"Debug test","data":"test data"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 2. 测试info级别日志 ---
print_header "2. 测试info级别日志"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/logs/test/info \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"message\":\"Info test\"}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/logs/test/info \
  -H "Content-Type: application/json" \
  -d '{"message":"Info test","status":"success"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 3. 测试warn级别日志 ---
print_header "3. 测试warn级别日志"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/logs/test/warn \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"message\":\"Warning test\"}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/logs/test/warn \
  -H "Content-Type: application/json" \
  -d '{"message":"Warning test","warning":"potential issue"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 4. 测试error级别日志 ---
print_header "4. 测试error级别日志"
echo "▶️  命令: curl -X POST ${BASE_URL}/api/logs/test/error \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"message\":\"Error test\"}'"
echo ""
echo "◀️  响应:"
curl -X POST ${BASE_URL}/api/logs/test/error \
  -H "Content-Type: application/json" \
  -d '{"message":"Error test","error":"test error"}' | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 5. 测试慢请求 (1秒延迟) ---
print_header "5. 测试慢请求 (1秒延迟)"
echo "▶️  命令: curl ${BASE_URL}/api/test/slow?delay=1000"
echo ""
echo "◀️  响应:"
curl -s "${BASE_URL}/api/test/slow?delay=1000" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 6. 测试慢请求 (3秒延迟) ---
print_header "6. 测试慢请求 (3秒延迟)"
echo "▶️  命令: curl ${BASE_URL}/api/test/slow?delay=3000"
echo ""
echo "◀️  响应:"
curl -s "${BASE_URL}/api/test/slow?delay=3000" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 7. 测试400错误 ---
print_header "7. 测试400错误"
echo "▶️  命令: curl ${BASE_URL}/api/test/error/400"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/test/error/400 | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 8. 测试404错误 ---
print_header "8. 测试404错误"
echo "▶️  命令: curl ${BASE_URL}/api/test/error/404"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/test/error/404 | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 9. 测试500错误 ---
print_header "9. 测试500错误"
echo "▶️  命令: curl ${BASE_URL}/api/test/error/500"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/test/error/500 | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 10. 获取日志记录 ---
print_header "10. 获取日志记录"
echo "▶️  命令: curl ${BASE_URL}/api/logs?limit=10"
echo ""
echo "◀️  响应:"
curl -s "${BASE_URL}/api/logs?limit=10" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 11. 获取日志统计 ---
print_header "11. 获取日志统计"
echo "▶️  命令: curl ${BASE_URL}/api/logs/stats"
echo ""
echo "◀️  响应:"
curl -s ${BASE_URL}/api/logs/stats | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 12. 按级别过滤日志 ---
print_header "12. 按级别过滤日志 (error)"
echo "▶️  命令: curl ${BASE_URL}/api/logs?level=error"
echo ""
echo "◀️  响应:"
curl -s "${BASE_URL}/api/logs?level=error" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 13. 按方法过滤日志 ---
print_header "13. 按方法过滤日志 (POST)"
echo "▶️  命令: curl ${BASE_URL}/api/logs?method=POST"
echo ""
echo "◀️  响应:"
curl -s "${BASE_URL}/api/logs?method=POST" | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 14. 生成多个请求以测试日志记录 ---
print_header "14. 生成多个请求以测试日志记录"
echo "发送10个请求..."
for i in {1..10}; do
  curl -s -X POST ${BASE_URL}/api/logs/test/info \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"Batch test $i\"}" > /dev/null
  echo "  请求 $i 完成"
done
echo ""
echo "◀️  查看日志统计:"
curl -s ${BASE_URL}/api/logs/stats | jq .
echo ""
echo "------------------------------------------------------------------------------"

# --- 15. 清除日志记录 ---
print_header "15. 清除日志记录"
echo "▶️  命令: curl -X DELETE ${BASE_URL}/api/logs"
echo ""
echo "◀️  响应:"
curl -X DELETE ${BASE_URL}/api/logs | jq .
echo ""
echo "------------------------------------------------------------------------------"

print_header "测试完成!"
echo "✅ 所有Logger测试用例执行完毕"
echo ""
echo "📝 测试总结:"
echo "   - Debug日志: ✓"
echo "   - Info日志: ✓"
echo "   - Warn日志: ✓"
echo "   - Error日志: ✓"
echo "   - 慢请求测试: ✓"
echo "   - 错误状态码测试: ✓"
echo "   - 日志查询: ✓"
echo "   - 日志统计: ✓"
echo "   - 日志过滤: ✓"
echo "   - 批量请求: ✓"
echo ""
