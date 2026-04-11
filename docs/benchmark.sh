#!/bin/bash

# WebServer 性能基准测试脚本
# 使用 Apache Bench (ab) 进行压力测试

echo "=========================================="
echo "WebServer 性能基准测试"
echo "=========================================="
echo ""

# 检查 ab 是否安装
if ! command -v ab &> /dev/null; then
    echo "错误: Apache Bench (ab) 未安装"
    echo "macOS 安装: brew install httpd"
    echo "Ubuntu 安装: sudo apt-get install apache2-utils"
    exit 1
fi

# 配置
HOST="127.0.0.1"
PORT="8080"
BASE_URL="http://${HOST}:${PORT}"

# 测试参数
CONCURRENT=100  # 并发连接数
REQUESTS=10000  # 总请求数

echo "测试配置:"
echo "  服务器: ${BASE_URL}"
echo "  并发数: ${CONCURRENT}"
echo "  请求数: ${REQUESTS}"
echo ""

# 等待服务器启动
echo "等待服务器启动..."
sleep 2

# 测试1: 简单GET请求
echo "=========================================="
echo "测试1: 简单GET请求 (/health)"
echo "=========================================="
ab -n ${REQUESTS} -c ${CONCURRENT} -k "${BASE_URL}/health"
echo ""

# 测试2: 静态文件
echo "=========================================="
echo "测试2: 静态文件请求"
echo "=========================================="
ab -n ${REQUESTS} -c ${CONCURRENT} -k "${BASE_URL}/index.html"
echo ""

# 测试3: JSON API
echo "=========================================="
echo "测试3: JSON API (POST)"
echo "=========================================="
ab -n 1000 -c 50 -k -p post_data.json -T "application/json" "${BASE_URL}/api/data"
echo ""

# 测试4: 带压缩的请求
echo "=========================================="
echo "测试4: 带Gzip压缩的请求"
echo "=========================================="
ab -n ${REQUESTS} -c ${CONCURRENT} -k -H "Accept-Encoding: gzip" "${BASE_URL}/health"
echo ""

# 测试5: 限流测试
echo "=========================================="
echo "测试5: 限流测试 (应该有部分429响应)"
echo "=========================================="
ab -n 200 -c 10 -k "${BASE_URL}/api/data"
echo ""

echo "=========================================="
echo "测试完成!"
echo "=========================================="
echo ""
echo "查看性能报告: curl ${BASE_URL}/metrics"
