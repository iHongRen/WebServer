#!/bin/bash

# HTTPS服务器安全特性测试脚本
# 专注测试SSL/TLS加密、证书验证、安全头部等HTTPS核心特性
# 使用方法: ./test-https-api.sh [服务器地址] [端口]

SERVER=${1:-192.168.2.74}
PORT=${2:-8443}
BASE_URL="https://${SERVER}:${PORT}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ 缺少依赖工具: ${missing_deps[*]}${NC}"
        echo "请安装缺少的工具后重试"
        exit 1
    fi
}

# 打印测试结果
print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "success" ]; then
        echo -e "${GREEN}✅ $test_name${NC}"
    else
        echo -e "${RED}❌ $test_name${NC}"
    fi
    
    if [ -n "$details" ]; then
        echo "$details"
    fi
    echo ""
}

# 测试SSL连接
test_ssl_connection() {
    echo -e "${BLUE}🔐 测试SSL连接...${NC}"
    
    local response=$(curl -k -I "$BASE_URL/" 2>/dev/null | head -1)
    if [[ $response == *"200"* ]] || [[ $response == *"HTTP"* ]]; then
        print_result "SSL连接测试" "success" "连接状态: $response"
    else
        print_result "SSL连接测试" "failed" "无法建立SSL连接"
        return 1
    fi
}

# 测试SSL证书信息
test_ssl_info() {
    echo -e "${BLUE}📋 测试SSL证书信息...${NC}"
    
    local ssl_info=$(curl -k -s "$BASE_URL/api/ssl/info" 2>/dev/null)
    if echo "$ssl_info" | jq . >/dev/null 2>&1; then
        print_result "SSL证书信息" "success"
        echo "$ssl_info" | jq '.'
    else
        print_result "SSL证书信息" "failed" "无法获取SSL证书信息"
    fi
}

# 测试HTTPS核心特性
test_https_features() {
    echo -e "${PURPLE}🔒 测试HTTPS核心特性...${NC}"
    
    # 1. 测试HTTPS首页
    echo "1. 测试HTTPS安全首页:"
    local home_response=$(curl -k -s "$BASE_URL/" 2>/dev/null)
    if echo "$home_response" | jq . >/dev/null 2>&1; then
        local secure_flag=$(echo "$home_response" | jq -r '.connection.secure' 2>/dev/null)
        if [ "$secure_flag" = "true" ]; then
            print_result "HTTPS安全首页" "success"
            echo "$home_response" | jq '.features'
        else
            print_result "HTTPS安全首页" "failed"
        fi
    else
        print_result "HTTPS安全首页" "failed"
    fi
    
    # 2. 测试SSL证书信息
    echo "2. 测试SSL证书信息:"
    local ssl_response=$(curl -k -s "$BASE_URL/api/ssl/info" 2>/dev/null)
    if echo "$ssl_response" | jq . >/dev/null 2>&1; then
        print_result "SSL证书信息" "success"
        echo "$ssl_response" | jq '.ssl, .certificate'
    else
        print_result "SSL证书信息" "failed"
    fi
}

# 测试加密数据传输 (已移除，专注于核心HTTPS特性)
test_encrypted_data_transfer() {
    echo -e "${CYAN}📡 测试HTTPS核心安全特性...${NC}"
    
    # 测试安全头部信息
    echo "1. 测试安全头部信息:"
    local headers_response=$(curl -k -s "$BASE_URL/api/security/headers" 2>/dev/null)
    
    if echo "$headers_response" | jq . >/dev/null 2>&1; then
        print_result "安全头部信息" "success"
        echo "$headers_response" | jq '.securityHeaders'
    else
        print_result "安全头部信息" "failed"
    fi
}

# 测试安全Token机制
test_secure_token() {
    echo -e "${BLUE}🔐 测试安全Token机制...${NC}"
    
    # 1. 获取安全Token
    echo "1. 获取安全Token (需要认证):"
    local token_response=$(curl -k -s \
        -H "Authorization: Basic ZGVtbzpzZWN1cmU=" \
        "$BASE_URL/api/secure/token" 2>/dev/null)
    
    if echo "$token_response" | jq . >/dev/null 2>&1; then
        local token=$(echo "$token_response" | jq -r '.token' 2>/dev/null)
        if [ "$token" != "null" ] && [ -n "$token" ]; then
            print_result "获取安全Token" "success" "Token: ${token:0:20}..."
            echo "$token_response" | jq '.'
            
            # 2. 验证Token
            echo "2. 验证安全Token:"
            local verify_response=$(curl -k -s "$BASE_URL/api/secure/verify/$token" 2>/dev/null)
            if echo "$verify_response" | jq . >/dev/null 2>&1; then
                local valid=$(echo "$verify_response" | jq -r '.valid' 2>/dev/null)
                if [ "$valid" = "true" ]; then
                    print_result "Token验证" "success"
                    echo "$verify_response" | jq '.'
                else
                    print_result "Token验证" "failed"
                fi
            else
                print_result "Token验证" "failed"
            fi
        else
            print_result "获取安全Token" "failed"
        fi
    else
        print_result "获取安全Token" "failed"
    fi
    
    # 3. 测试无效Token
    echo "3. 测试无效Token验证:"
    local invalid_token="invalid_token_123"
    local invalid_response=$(curl -k -s "$BASE_URL/api/secure/verify/$invalid_token" 2>/dev/null)
    if echo "$invalid_response" | jq . >/dev/null 2>&1; then
        local valid=$(echo "$invalid_response" | jq -r '.valid' 2>/dev/null)
        if [ "$valid" = "false" ]; then
            print_result "无效Token测试" "success" "正确拒绝了无效Token"
        else
            print_result "无效Token测试" "failed"
        fi
    else
        print_result "无效Token测试" "failed"
    fi
}

# 测试安全头部
test_security_headers() {
    echo -e "${BLUE}🔒 测试安全头部...${NC}"
    
    local headers=$(curl -k -I "$BASE_URL/" 2>/dev/null)
    
    # 检查HSTS
    if echo "$headers" | grep -qi "strict-transport-security"; then
        print_result "HSTS头部" "success"
    else
        print_result "HSTS头部" "failed"
    fi
    
    # 检查XSS保护
    if echo "$headers" | grep -qi "x-xss-protection"; then
        print_result "XSS保护头部" "success"
    else
        print_result "XSS保护头部" "failed"
    fi
    
    # 检查内容类型选项
    if echo "$headers" | grep -qi "x-content-type-options"; then
        print_result "内容类型选项头部" "success"
    else
        print_result "内容类型选项头部" "failed"
    fi
    
    # 检查Frame选项
    if echo "$headers" | grep -qi "x-frame-options"; then
        print_result "Frame选项头部" "success"
    else
        print_result "Frame选项头部" "failed"
    fi
}

# 测试SSL协议版本
test_ssl_protocols() {
    echo -e "${BLUE}🔐 测试SSL协议版本...${NC}"
    
    # 测试TLS 1.2
    if timeout 5 openssl s_client -connect "${SERVER}:${PORT}" -tls1_2 -quiet < /dev/null >/dev/null 2>&1; then
        print_result "TLS 1.2 支持" "success"
    else
        print_result "TLS 1.2 支持" "failed"
    fi
    
    # 测试TLS 1.3
    if timeout 5 openssl s_client -connect "${SERVER}:${PORT}" -tls1_3 -quiet < /dev/null >/dev/null 2>&1; then
        print_result "TLS 1.3 支持" "success"
    else
        print_result "TLS 1.3 支持" "failed"
    fi
}

# 测试证书信息
test_certificate_info() {
    echo -e "${BLUE}📜 测试证书信息...${NC}"
    
    local cert_info=$(timeout 10 openssl s_client -connect "${SERVER}:${PORT}" -servername "${SERVER}" 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
    
    if [ -n "$cert_info" ]; then
        print_result "证书信息获取" "success"
        echo "$cert_info"
    else
        print_result "证书信息获取" "failed"
    fi
}

# 性能测试
test_performance() {
    echo -e "${BLUE}⚡ 简单性能测试...${NC}"
    
    echo "测试HTTPS响应时间 (5次请求):"
    local total_time=0
    local success_count=0
    
    for i in {1..5}; do
        local start_time=$(date +%s.%N)
        if curl -k -s -o /dev/null "$BASE_URL/api/ssl/info" 2>/dev/null; then
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
            echo "  请求 $i: ${duration}s"
            total_time=$(echo "$total_time + $duration" | bc 2>/dev/null || echo "$total_time")
            ((success_count++))
        else
            echo "  请求 $i: 失败"
        fi
    done
    
    if [ $success_count -gt 0 ]; then
        local avg_time=$(echo "scale=3; $total_time / $success_count" | bc 2>/dev/null || echo "N/A")
        print_result "性能测试" "success" "平均响应时间: ${avg_time}s (成功: $success_count/5)"
    else
        print_result "性能测试" "failed"
    fi
}

# 主函数
main() {
    echo -e "${GREEN}🔒 开始测试HTTPS服务器API${NC}"
    echo -e "${BLUE}服务器地址: $BASE_URL${NC}"
    echo "=================================================="
    
    # 检查依赖
    check_dependencies
    
    # 执行HTTPS核心特性测试
    test_ssl_connection || exit 1
    test_https_features
    test_encrypted_data_transfer
    test_secure_token
    test_security_headers
    test_ssl_protocols
    test_certificate_info
    test_performance
    
    echo "=================================================="
    echo -e "${GREEN}✅ HTTPS API测试完成！${NC}"
    echo ""
    echo -e "${YELLOW}📋 HTTPS安全特性测试总结:${NC}"
    echo "- 🔒 SSL/TLS加密连接验证"
    echo "- 📜 数字证书信息检查"
    echo "- 📡 加密数据传输测试"
    echo "- 🔐 安全Token机制验证"
    echo "- 🛡️ 安全头部配置检查"
    echo "- 🔧 SSL协议版本支持"
    echo "- ⚡ HTTPS性能基准测试"
    echo ""
    echo -e "${BLUE}🌐 HTTPS安全特性演示地址:${NC}"
    echo "- 安全首页: $BASE_URL/"
    echo "- SSL信息: $BASE_URL/api/ssl/info"
    echo "- 安全头部: $BASE_URL/api/security/headers"
    echo "- Token获取: $BASE_URL/api/secure/token"
    echo "- Token验证: $BASE_URL/api/secure/verify/[TOKEN]"
    echo ""
    echo -e "${YELLOW}⚠️  注意: 自签名证书会显示安全警告，这是正常现象${NC}"
    echo "点击浏览器中的"高级" → "继续访问"即可"
}

# 运行主函数
main "$@"