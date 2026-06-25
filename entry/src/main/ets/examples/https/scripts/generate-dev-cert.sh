#!/bin/bash

# 快速生成开发环境证书脚本
# 用法: ./generate-dev-cert.sh [IP地址]

IP=${1:-192.168.2.74}
DAYS=365

echo "🚀 快速生成开发环境HTTPS证书"
echo "IP地址: $IP"

# 一步生成自签名证书（适合开发环境）
openssl req -x509 -newkey rsa:2048 -keyout dev-key.pem -out dev-cert.pem -days $DAYS -nodes \
  -subj "/C=CN/ST=Dev/L=Dev/O=Dev/OU=Dev/CN=$IP" \
  -addext "subjectAltName=IP:$IP,IP:127.0.0.1,DNS:localhost"

if [ $? -eq 0 ]; then
    chmod 600 dev-key.pem
    chmod 644 dev-cert.pem
    
    echo "✅ 开发证书生成成功!"
    echo "📁 文件: dev-key.pem, dev-cert.pem"
    echo ""
    echo "📋 代码使用:"
    echo "const tlsOptions = await CertificateManager.loadFromFiles('dev-key.pem', 'dev-cert.pem');"
else
    echo "❌ 证书生成失败"
    exit 1
fi