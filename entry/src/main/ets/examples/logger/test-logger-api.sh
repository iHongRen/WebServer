#!/bin/bash

# Logger API 测试脚本
# 使用方法: ./test-logger-api.sh [server_url]
# 默认服务器地址: http://localhost:8085

SERVER_URL=${1:-"http://localhost:8085"}
echo "🧪 测试 Logger API"
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

echo -e "${YELLOW}📄 演示页面测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/logger-demo.html" "Logger演示页面"
test_api "GET" "/log-viewer.html" "日志查看器"

echo -e "${YELLOW}📊 日志查询API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/logs" "获取日志记录"
test_api "GET" "/api/logs?limit=5" "获取最近5条日志"
test_api "GET" "/api/logs?level=info" "按级别过滤日志"
test_api "GET" "/api/logs?method=GET" "按方法过滤日志"
test_api "GET" "/api/logs/stats" "获取日志统计"

echo -e "${YELLOW}⚙️ 日志配置API测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

test_api "GET" "/api/logs/config" "获取日志配置"

# 测试不同的日志格式
echo -e "${BLUE}🔍 测试: 更新日志格式${NC}"
formats=("dev" "combined" "common" "short" "tiny")
for format in "${formats[@]}"; do
    echo "   设置格式为: $format"
    test_api "POST" "/api/logs/config" "更新日志格式为$format" "{\"logFormat\": \"$format\"}"
done

# 测试不同的日志级别
echo -e "${BLUE}🔍 测试: 更新日志级别${NC}"
levels=("debug" "info" "warn" "error")
for level in "${levels[@]}"; do
    echo "   设置级别为: $level"
    test_api "POST" "/api/logs/config" "更新日志级别为$level" "{\"logLevel\": \"$level\"}"
done

echo -e "${YELLOW}🧪 日志测试API${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 测试不同级别的日志
test_api "POST" "/api/logs/test/debug" "测试debug日志" '{"message": "这是一个debug日志测试"}'
test_api "POST" "/api/logs/test/info" "测试info日志" '{"message": "这是一个info日志测试"}'
test_api "POST" "/api/logs/test/warn" "测试warn日志" '{"message": "这是一个warn日志测试"}'
test_api "POST" "/api/logs/test/error" "测试error日志" '{"message": "这是一个error日志测试"}'

echo -e "${YELLOW}⏱️ 性能测试API${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 慢请求测试
test_api "GET" "/api/test/slow" "默认慢请求测试(1秒)"
test_api "GET" "/api/test/slow?delay=500" "自定义慢请求测试(0.5秒)"

# 错误状态码测试
test_api "GET" "/api/test/error/400" "400错误测试" "" 400
test_api "GET" "/api/test/error/401" "401错误测试" "" 401
test_api "GET" "/api/test/error/404" "404错误测试" "" 404
test_api "GET" "/api/test/error/500" "500错误测试" "" 500

echo -e "${YELLOW}📈 日志统计验证${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 验证日志统计数据${NC}"
echo "   获取统计数据..."

response=$(curl -s "$SERVER_URL/api/logs/stats")
echo "   📊 统计数据: $response"

# 解析统计数据
total_logs=$(echo "$response" | grep -o '"totalLogs":[0-9]*' | cut -d':' -f2)
error_rate=$(echo "$response" | grep -o '"errorRate":[0-9.]*' | cut -d':' -f2)

if [ -n "$total_logs" ]; then
    echo "   📝 总日志数: $total_logs"
else
    echo "   ⚠️  无法获取总日志数"
fi

if [ -n "$error_rate" ]; then
    echo "   📊 错误率: $error_rate%"
else
    echo "   ⚠️  无法获取错误率"
fi
echo

echo -e "${YELLOW}🔄 并发测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

echo -e "${BLUE}🔍 测试: 并发日志记录${NC}"
echo "   发送20个并发请求..."

start_time=$(date +%s%N)
for i in {1..20}; do
    curl -s "$SERVER_URL/api/logs/test/info" \
         -H "Content-Type: application/json" \
         -d "{\"message\": \"并发测试请求 #$i\"}" > /dev/null &
done
wait
end_time=$(date +%s%N)

duration=$(( (end_time - start_time) / 1000000 ))
echo "   总耗时: ${duration}ms"
echo "   平均响应时间: $((duration / 20))ms"

# 验证日志是否都被记录
sleep 1
response=$(curl -s "$SERVER_URL/api/logs?limit=25")
concurrent_logs=$(echo "$response" | grep -o "并发测试请求" | wc -l)
echo "   记录的并发日志数: $concurrent_logs/20"

if [ "$concurrent_logs" -eq 20 ]; then
    echo -e "   ${GREEN}✅ 所有并发日志都被正确记录${NC}"
else
    echo -e "   ${YELLOW}⚠️  部分并发日志可能丢失${NC}"
fi
echo

echo -e "${YELLOW}🧹 清理测试${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 获取清理前的日志数量
response=$(curl -s "$SERVER_URL/api/logs/stats")
before_count=$(echo "$response" | grep -o '"totalLogs":[0-9]*' | cut -d':' -f2)
echo "清理前日志数量: $before_count"

# 清理日志
test_api "DELETE" "/api/logs" "清除所有日志记录"

# 验证清理结果
response=$(curl -s "$SERVER_URL/api/logs/stats")
after_count=$(echo "$response" | grep -o '"totalLogs":[0-9]*' | cut -d':' -f2)
echo "清理后日志数量: $after_count"

if [ "$after_count" -eq 0 ]; then
    echo -e "${GREEN}✅ 日志清理成功${NC}"
else
    echo -e "${YELLOW}⚠️  日志清理可能不完整${NC}"
fi
echo

echo -e "${YELLOW}📋 日志格式验证${NC}"
echo "=" | tr '=' '-' | head -c 30; echo

# 重置为dev格式并生成一些日志
curl -s -X POST "$SERVER_URL/api/logs/config" \
     -H "Content-Type: application/json" \
     -d '{"logFormat": "dev"}' > /dev/null

# 生成测试日志
curl -s "$SERVER_URL/" > /dev/null
curl -s "$SERVER_URL/api/logs" > /dev/null

echo -e "${BLUE}🔍 测试: 验证不同日志格式${NC}"
formats=("dev" "combined" "common" "short" "tiny")
for format in "${formats[@]}"; do
    # 设置格式
    curl -s -X POST "$SERVER_URL/api/logs/config" \
         -H "Content-Type: application/json" \
         -d "{\"logFormat\": \"$format\"}" > /dev/null
    
    # 生成一个请求来测试格式
    curl -s "$SERVER_URL/api/logs/test/info" \
         -H "Content-Type: application/json" \
         -d "{\"message\": \"测试$format格式\"}" > /dev/null
    
    echo "   ✅ $format 格式测试完成"
done
echo

echo -e "${GREEN}🎉 Logger API 测试完成!${NC}"
echo "📊 查看详细统计: curl $SERVER_URL/api/logs/stats"
echo "📋 查看日志记录: curl $SERVER_URL/api/logs"
echo "⚙️  查看配置信息: curl $SERVER_URL/api/logs/config"