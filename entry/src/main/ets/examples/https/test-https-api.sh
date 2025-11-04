#!/bin/bash

# HTTPS服务器API测试脚本
# 使用方法: ./test-https-api.sh [服务器地址] [端口]

SERVER=${1:-192.168.2.38}
PORT=${2:-8443}
BASE_URL="https://${SERVER}:${PORT}"

echo "🔒 开始测试HTTPS服务器API"
echo "服务器地址: $BASE_URL"
echo "=" * 50

# 测试SSL连接
echo "🔐 测试SSL连接..."
curl -k -I "$BASE_URL/" | head -1 || echo "❌ SSL连接测试失败"
echo ""

# 测试SSL证书信息
echo "📋 测试SSL证书信息..."
curl -k -s "$BASE_URL/api/ssl/info" | jq '.' || echo "❌ SSL证书信息测试失败"
echo ""

# 测试安全用户API
echo "👥 测试安全用户管理API..."

# 获取安全用户列表
echo "1. 获取安全用户列表:"
curl -k -s "$BASE_URL/api/secure/users" | jq '.' || echo "❌ 获取安全用户列表失败"
echo ""

# 创建安全用户
echo "2. 创建安全用户:"
NEW_USER=$(curl -k -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"SecureUser","email":"secure@example.com"}' \
  "$BASE_URL/api/secure/users")
echo $NEW_USER | jq '.' || echo "❌ 创建安全用户失败"
echo ""

# 测试安全登录
echo "3. 测试安全登录:"
LOGIN_RESULT=$(curl -k -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}' \
  "$BASE_URL/api/secure/login")
echo $LOGIN_RESULT | jq '.' || echo "❌ 安全登录测试失败"

# 提取token
TOKEN=$(echo $LOGIN_RESULT | jq -r '.token' 2>/dev/null)
echo "获取的安全token: $TOKEN"
echo ""

# 测试安全文件上传
echo "📁 测试安全文件上传..."
echo "This is a secure test file" > /tmp/secure-test.txt
curl -k -s -X POST \
  -F "uploadFile=@/tmp/secure-test.txt" \
  "$BASE_URL/api/secure/upload" | jq '.' || echo "❌ 安全文件上传失败"
rm -f /tmp/secure-test.txt
echo ""

# 测试安全测试端点
echo "🛡️  测试安全测试端点..."
curl -k -s -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/api/security/test" | jq '.' || echo "❌ 安全测试端点失败"
echo ""

# 测试安全头部
echo "🔒 测试安全头部..."
echo "检查HSTS头部:"
curl -k -I "$BASE_URL/" | grep -i "strict-transport-security" || echo "❌ HSTS头部未找到"

echo "检查XSS保护头部:"
curl -k -I "$BASE_URL/" | grep -i "x-xss-protection" || echo "❌ XSS保护头部未找到"

echo "检查内容类型头部:"
curl -k -I "$BASE_URL/" | grep -i "x-content-type-options" || echo "❌ 内容类型头部未找到"
echo ""

# 测试SSL协议版本
echo "🔐 测试SSL协议版本..."
echo "测试TLS 1.2连接:"
timeout 5 openssl s_client -connect ${SERVER}:${PORT} -tls1_2 -quiet < /dev/null 2>/dev/null && echo "✅ TLS 1.2 支持" || echo "❌ TLS 1.2 不支持"

echo "测试TLS 1.3连接:"
timeout 5 openssl s_client -connect ${SERVER}:${PORT} -tls1_3 -quiet < /dev/null 2>/dev/null && echo "✅ TLS 1.3 支持" || echo "❌ TLS 1.3 不支持"
echo ""

# 测试证书有效性
echo "📜 测试证书有效性..."
echo "证书基本信息:"
timeout 5 openssl s_client -connect ${SERVER}:${PORT} -servername ${SERVER} 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "❌ 无法获取证书信息"
echo ""

# 性能测试
echo "⚡ 简单性能测试..."
echo "测试HTTPS响应时间:"
time curl -k -s -o /dev/null "$BASE_URL/api/ssl/info" || echo "❌ 性能测试失败"
echo ""

echo "✅ HTTPS API测试完成！"
echo ""
echo "📋 测试总结:"
echo "- SSL/TLS连接测试"
echo "- 安全用户管理API"
echo "- 安全登录认证"
echo "- 安全文件上传"
echo "- 安全头部验证"
echo "- SSL协议版本检查"
echo "- 证书有效性验证"
echo ""
echo "🌐 可以通过浏览器访问以下地址进行进一步测试:"
echo "- HTTPS首页: $BASE_URL/"
echo "- SSL信息: $BASE_URL/api/ssl/info"
echo "- 安全测试: $BASE_URL/api/security/test"
echo ""
echo "⚠️  注意: 自签名证书会显示安全警告，这是正常现象"