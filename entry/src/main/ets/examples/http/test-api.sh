#!/bin/bash

# HTTP服务器API测试脚本
# 使用方法: ./test-api.sh [服务器地址] [端口]

SERVER=${1:-192.168.2.38}
PORT=${2:-8080}
BASE_URL="http://${SERVER}:${PORT}"

echo "🧪 开始测试HTTP服务器API"
echo "服务器地址: $BASE_URL"
echo "=" * 50

# 测试服务器状态
echo "📊 测试服务器状态..."
curl -s "$BASE_URL/api/status" | jq '.' || echo "❌ 服务器状态测试失败"
echo ""

# 测试用户API
echo "👥 测试用户管理API..."

# 获取用户列表
echo "1. 获取用户列表:"
curl -s "$BASE_URL/api/users" | jq '.' || echo "❌ 获取用户列表失败"
echo ""

# 创建新用户
echo "2. 创建新用户:"
NEW_USER=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"TestUser","email":"test@example.com"}' \
  "$BASE_URL/api/users")
echo $NEW_USER | jq '.' || echo "❌ 创建用户失败"

# 提取用户ID
USER_ID=$(echo $NEW_USER | jq -r '.user.id' 2>/dev/null)
echo "创建的用户ID: $USER_ID"
echo ""

# 获取单个用户
if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
  echo "3. 获取单个用户 (ID: $USER_ID):"
  curl -s "$BASE_URL/api/users/$USER_ID" | jq '.' || echo "❌ 获取单个用户失败"
  echo ""

  # 更新用户
  echo "4. 更新用户 (ID: $USER_ID):"
  curl -s -X PUT \
    -H "Content-Type: application/json" \
    -d '{"name":"UpdatedUser","email":"updated@example.com"}' \
    "$BASE_URL/api/users/$USER_ID" | jq '.' || echo "❌ 更新用户失败"
  echo ""
fi

# 测试分页和搜索
echo "5. 测试分页查询:"
curl -s "$BASE_URL/api/users?page=1&limit=2" | jq '.' || echo "❌ 分页查询失败"
echo ""

echo "6. 测试搜索功能:"
curl -s "$BASE_URL/api/users?search=test" | jq '.' || echo "❌ 搜索功能失败"
echo ""

# 测试工具API
echo "🔧 测试工具API..."

echo "1. 测试请求头信息:"
curl -s -H "X-Custom-Header: TestValue" "$BASE_URL/api/headers" | jq '.' || echo "❌ 请求头测试失败"
echo ""

echo "2. 测试回显功能:"
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello World","timestamp":"'$(date -Iseconds)'"}' \
  "$BASE_URL/api/echo" | jq '.' || echo "❌ 回显测试失败"
echo ""

# 测试错误处理
echo "🚨 测试错误处理..."

echo "1. 测试验证错误:"
curl -s "$BASE_URL/api/error?type=validation" | jq '.' || echo "❌ 验证错误测试失败"
echo ""

echo "2. 测试超时错误:"
curl -s "$BASE_URL/api/error?type=timeout" | jq '.' || echo "❌ 超时错误测试失败"
echo ""

# 测试文件API
echo "📁 测试文件管理API..."

echo "1. 获取文件列表:"
curl -s "$BASE_URL/api/files" | jq '.' || echo "❌ 获取文件列表失败"
echo ""

# 创建测试文件并上传
echo "2. 测试文件上传:"
echo "This is a test file content" > /tmp/test-upload.txt
curl -s -X POST \
  -F "uploadFile=@/tmp/test-upload.txt" \
  "$BASE_URL/api/upload" | jq '.' || echo "❌ 文件上传失败"
rm -f /tmp/test-upload.txt
echo ""

# 测试静态文件
echo "📄 测试静态文件服务..."
echo "1. 测试首页访问:"
curl -s -I "$BASE_URL/" | head -1 || echo "❌ 首页访问失败"
echo ""

echo "2. 测试上传页面:"
curl -s -I "$BASE_URL/upload.html" | head -1 || echo "❌ 上传页面访问失败"
echo ""

# 清理：删除测试用户
if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
  echo "🧹 清理测试数据..."
  echo "删除测试用户 (ID: $USER_ID):"
  curl -s -X DELETE "$BASE_URL/api/users/$USER_ID" | jq '.' || echo "❌ 删除用户失败"
  echo ""
fi

echo "✅ API测试完成！"
echo ""
echo "📋 测试总结:"
echo "- 用户管理API: CRUD操作"
echo "- 分页和搜索功能"
echo "- 文件上传下载"
echo "- 错误处理机制"
echo "- 静态文件服务"
echo ""
echo "🌐 可以通过浏览器访问以下地址进行进一步测试:"
echo "- 首页: $BASE_URL/"
echo "- 文件上传: $BASE_URL/upload.html"
echo "- 服务器状态: $BASE_URL/api/status"