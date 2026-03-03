#!/bin/bash

# Router API 测试脚本
# 使用方法: ./test-router-api.sh [server_url]
# 默认服务器地址: http://localhost:8080

SERVER_URL=${1:-"http://localhost:8080"}
echo "🧪 测试 Router API"
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

echo -e "${YELLOW}🏠 基础路由测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/" "首页路由"
test_api "GET" "/about" "关于页面路由"
test_api "GET" "/contact" "联系页面路由"

echo -e "${YELLOW}🔗 参数路由测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 单个参数路由
test_api "GET" "/api/users/123" "用户详情路由 (ID: 123)"
test_api "GET" "/api/users/456" "用户详情路由 (ID: 456)"

# 多个参数路由
test_api "GET" "/api/products/electronics/789" "产品详情路由 (分类: electronics, ID: 789)"
test_api "GET" "/api/products/books/101" "产品详情路由 (分类: books, ID: 101)"

# 带查询参数的路由
test_api "GET" "/api/posts/555?format=json" "文章详情路由 (JSON格式)"
test_api "GET" "/api/posts/666?format=xml" "文章详情路由 (XML格式)"

echo -e "${YELLOW}🌟 通配符路由测试 (通过中间件处理)${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 注意：这些路由通过动态中间件处理，可能返回404或其他响应
test_api "GET" "/files/documents/readme.txt" "文件访问 (文档)" 404
test_api "GET" "/files/images/logo.png" "文件访问 (图片)" 404
test_api "GET" "/files/videos/demo.mp4" "文件访问 (视频)" 404
test_api "GET" "/files/nested/folder/file.pdf" "文件访问 (嵌套路径)" 404

echo -e "${YELLOW}⚙️ 路由管理API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/routes/stats" "获取路由统计"
test_api "GET" "/api/routes/records" "获取路由记录"
test_api "GET" "/api/routes/records?limit=5" "获取最近5条路由记录"
test_api "GET" "/api/routes/records?method=GET" "按GET方法过滤路由记录"

echo -e "${YELLOW}🔄 动态路由测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 添加动态路由
echo -e "${BLUE}🔍 测试: 添加动态路由${NC}"

# 添加GET路由
test_api "POST" "/api/routes" "添加动态GET路由" '{
  "method": "GET",
  "path": "/api/test-dynamic",
  "response": {"message": "这是一个动态GET路由", "type": "dynamic"}
}'

# 添加POST路由
test_api "POST" "/api/routes" "添加动态POST路由" '{
  "method": "POST", 
  "path": "/api/test-post",
  "response": {"message": "这是一个动态POST路由", "method": "POST"}
}'

# 获取所有动态路由
test_api "GET" "/api/routes/dynamic" "获取所有动态路由"

# 测试动态路由是否工作
echo -e "${BLUE}🔍 测试: 访问动态路由${NC}"
test_api "GET" "/api/test-dynamic" "访问动态GET路由"

# 删除动态路由
echo -e "${BLUE}🔍 测试: 删除动态路由${NC}"
test_api "DELETE" "/api/routes/GET/api/test-dynamic" "删除动态GET路由"

# 验证路由已被删除 (应该返回404或其他错误)
echo -e "${BLUE}🔍 测试: 验证路由已删除${NC}"
echo "   访问已删除的路由 (应该失败)"
response=$(curl -s -w "\n%{http_code}" "$SERVER_URL/api/test-dynamic")
status_code=$(echo "$response" | tail -n1)
if [ "$status_code" -ne 200 ]; then
    echo -e "   ${GREEN}✅ 路由删除成功 (状态码: $status_code)${NC}"
else
    echo -e "   ${YELLOW}⚠️  路由可能未被正确删除${NC}"
fi
echo

echo -e "${YELLOW}📊 路由统计验证${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 验证路由统计数据${NC}"

# 生成一些路由访问来测试统计
echo "   生成测试数据..."
for i in {1..5}; do
    curl -s "$SERVER_URL/api/users/$i" > /dev/null
    curl -s "$SERVER_URL/api/products/category$i/$i" > /dev/null
done

# 获取统计数据
response=$(curl -s "$SERVER_URL/api/routes/stats")
echo "   📊 统计数据: $response"

# 解析统计数据
total_requests=$(echo "$response" | grep -o '"totalRequests":[0-9]*' | cut -d':' -f2)
avg_response_time=$(echo "$response" | grep -o '"averageResponseTime":[0-9.]*' | cut -d':' -f2)

if [ -n "$total_requests" ]; then
    echo "   📝 总请求数: $total_requests"
else
    echo "   ⚠️  无法获取总请求数"
fi

if [ -n "$avg_response_time" ]; then
    echo "   ⏱️  平均响应时间: ${avg_response_time}ms"
else
    echo "   ⚠️  无法获取平均响应时间"
fi
echo

echo -e "${YELLOW}🔄 并发路由测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 并发路由访问${NC}"
echo "   发送20个并发请求到不同路由..."

start_time=$(date +%s%N)

# 并发访问不同的路由
for i in {1..20}; do
    case $((i % 4)) in
        0) curl -s "$SERVER_URL/api/users/$i" > /dev/null &;;
        1) curl -s "$SERVER_URL/api/products/test/$i" > /dev/null &;;
        2) curl -s "$SERVER_URL/files/test$i.txt" > /dev/null &;;
        3) curl -s "$SERVER_URL/api/posts/$i" > /dev/null &;;
    esac
done
wait

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "   总耗时: ${duration}ms"
echo "   平均响应时间: $((duration / 20))ms"

# 验证路由记录
sleep 1
response=$(curl -s "$SERVER_URL/api/routes/records?limit=25")
recent_records=$(echo "$response" | grep -o '"id":[0-9]*' | wc -l)
echo "   最近记录数: $recent_records"

if [ "$recent_records" -ge 20 ]; then
    echo -e "   ${GREEN}✅ 并发路由访问记录正常${NC}"
else
    echo -e "   ${YELLOW}⚠️  部分并发请求可能未被记录${NC}"
fi
echo

echo -e "${YELLOW}🧪 路由边界测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 测试特殊字符和边界情况
echo -e "${BLUE}🔍 测试: 特殊字符和边界情况${NC}"

# 测试数字ID
test_api "GET" "/api/users/0" "用户ID为0"
test_api "GET" "/api/users/999999" "用户ID为大数字"

# 测试特殊字符 (URL编码)
test_api "GET" "/api/users/test%20user" "用户ID包含空格"
test_api "GET" "/files/test%2Ffile.txt" "文件路径包含斜杠"

# 测试长路径
long_path="/files/very/long/nested/path/with/many/segments/file.txt"
test_api "GET" "$long_path" "长路径测试"

# 测试不存在的路由 (应该返回404或其他错误)
echo -e "${BLUE}🔍 测试: 不存在的路由${NC}"
response=$(curl -s -w "\n%{http_code}" "$SERVER_URL/nonexistent/route")
status_code=$(echo "$response" | tail -n1)
echo "   访问不存在的路由: /nonexistent/route"
echo "   状态码: $status_code"
if [ "$status_code" -eq 404 ] || [ "$status_code" -eq 500 ]; then
    echo -e "   ${GREEN}✅ 正确处理不存在的路由${NC}"
else
    echo -e "   ${YELLOW}⚠️  路由处理可能需要优化${NC}"
fi
echo

echo -e "${YELLOW}🧹 清理测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 获取清理前的记录数量
response=$(curl -s "$SERVER_URL/api/routes/stats")
before_count=$(echo "$response" | grep -o '"totalRequests":[0-9]*' | cut -d':' -f2)
echo "清理前路由记录数量: $before_count"

# 清理路由记录
test_api "DELETE" "/api/routes/records" "清除所有路由记录"

# 验证清理结果
response=$(curl -s "$SERVER_URL/api/routes/stats")
after_count=$(echo "$response" | grep -o '"totalRequests":[0-9]*' | cut -d':' -f2)
echo "清理后路由记录数量: $after_count"

if [ "$after_count" -eq 0 ]; then
    echo -e "${GREEN}✅ 路由记录清理成功${NC}"
else
    echo -e "${YELLOW}⚠️  路由记录清理可能不完整${NC}"
fi
echo

echo -e "${YELLOW}📈 性能基准测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 路由性能基准${NC}"

# 测试不同类型路由的性能
routes=(
    "/"
    "/api/users/123"
    "/api/products/electronics/456"
    "/files/test/file.txt"
    "/api/v1/status"
)

for route in "${routes[@]}"; do
    echo "   测试路由: $route"
    
    start_time=$(date +%s%N)
    for i in {1..10}; do
        curl -s "$SERVER_URL$route" > /dev/null
    done
    end_time=$(date +%s%N)
    
    duration=$(( (end_time - start_time) / 1000000 ))
    avg_time=$((duration / 10))
    echo "   平均响应时间: ${avg_time}ms"
done
echo

echo -e "${GREEN}🎉 Router API 测试完成!${NC}"
echo "📊 查看详细统计: curl $SERVER_URL/api/routes/stats"
echo "📋 查看路由记录: curl $SERVER_URL/api/routes/records"
echo "🔧 管理动态路由: curl $SERVER_URL/api/routes/dynamic"
echo "🧪 使用测试工具: $SERVER_URL/route-tester.html"