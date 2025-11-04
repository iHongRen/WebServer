#!/bin/bash

# Static File Server API 测试脚本
# 使用方法: ./test-static-api.sh [server_url]
# 默认服务器地址: http://localhost:8087

SERVER_URL=${1:-"http://localhost:8087"}
echo "🧪 测试 Static File Server API"
echo "📍 服务器地址: $SERVER_URL"
echo "=" | tr '=' '=' | head -c 50; echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试函数
test_api() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local expected_status=${5:-200}
    
    echo -e "${BLUE}🔍 测试: $description${NC}"
    echo "   $method $endpoint"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$SERVER_URL$endpoint")
    elif [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$SERVER_URL$endpoint")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$SERVER_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$SERVER_URL$endpoint")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "   ${GREEN}✅ 成功 (状态码: $status_code)${NC}"
        if [ ${#body} -gt 200 ]; then
            echo "   📄 响应: $(echo "$body" | head -c 200)..."
        else
            echo "   📄 响应: $body"
        fi
    else
        echo -e "   ${RED}❌ 失败 (期望: $expected_status, 实际: $status_code)${NC}"
        echo "   📄 响应: $body"
    fi
    echo
}

# 测试文件上传
test_file_upload() {
    echo -e "${BLUE}🔍 测试: 文件上传${NC}"
    echo "   POST /api/upload"
    
    # 创建测试文件
    echo "This is a test file for upload" > test_upload.txt
    
    response=$(curl -s -w "\n%{http_code}" -X POST -F "file=@test_upload.txt" "$SERVER_URL/api/upload")
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$status_code" -eq 200 ]; then
        echo -e "   ${GREEN}✅ 成功 (状态码: $status_code)${NC}"
        echo "   📄 响应: $body"
    else
        echo -e "   ${RED}❌ 失败 (状态码: $status_code)${NC}"
        echo "   📄 响应: $body"
    fi
    
    # 清理测试文件
    rm -f test_upload.txt
    echo
}

echo -e "${YELLOW}📄 静态文件访问测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/" "获取首页"
test_api "GET" "/css/style.css" "获取CSS文件"
test_api "GET" "/js/app.js" "获取JavaScript文件"
test_api "GET" "/data.json" "获取JSON数据"
test_api "GET" "/docs/readme.txt" "获取文档文件"

echo -e "${YELLOW}📂 文件管理API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/files" "文件浏览器"
test_api "GET" "/api/files?path=css" "浏览CSS目录"
test_file_upload
test_api "GET" "/api/file-info/data.json" "获取文件信息"

echo -e "${YELLOW}📊 统计分析API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/stats" "获取访问统计"
test_api "GET" "/api/access-log" "获取访问日志"
test_api "GET" "/api/access-log?limit=5" "获取最近5条日志"

echo -e "${YELLOW}⚙️ 配置管理API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/config" "获取服务器配置"
test_api "POST" "/api/config/cache" "更新缓存配置" '{"enableCache": true, "maxAge": 7200}'

echo -e "${YELLOW}🧪 缓存测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 缓存机制${NC}"
echo "   第一次请求 (应该是 200)"
response1=$(curl -s -w "\n%{http_code}" -I "$SERVER_URL/css/style.css")
status1=$(echo "$response1" | tail -n1)
etag=$(echo "$response1" | grep -i "etag:" | cut -d' ' -f2- | tr -d '\r')

echo "   状态码: $status1"
echo "   ETag: $etag"

if [ -n "$etag" ]; then
    echo "   第二次请求带 If-None-Match (应该是 304)"
    response2=$(curl -s -w "\n%{http_code}" -I -H "If-None-Match: $etag" "$SERVER_URL/css/style.css")
    status2=$(echo "$response2" | tail -n1)
    echo "   状态码: $status2"
    
    if [ "$status2" -eq 304 ]; then
        echo -e "   ${GREEN}✅ 缓存机制正常工作${NC}"
    else
        echo -e "   ${YELLOW}⚠️  缓存可能未正确配置${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  未找到 ETag 头${NC}"
fi
echo

echo -e "${YELLOW}🔄 清理测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "DELETE" "/api/access-log" "清除访问日志"

echo -e "${YELLOW}📈 性能测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 并发请求性能${NC}"
echo "   发送10个并发请求到首页..."

start_time=$(date +%s%N)
for i in {1..10}; do
    curl -s "$SERVER_URL/" > /dev/null &
done
wait
end_time=$(date +%s%N)

duration=$(( (end_time - start_time) / 1000000 ))
echo "   总耗时: ${duration}ms"
echo "   平均响应时间: $((duration / 10))ms"
echo

echo -e "${GREEN}🎉 Static File Server API 测试完成!${NC}"
echo "📊 查看详细统计: curl $SERVER_URL/api/stats"
echo "📋 查看访问日志: curl $SERVER_URL/api/access-log"