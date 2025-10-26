#!/bin/bash

# 创建自签名证书脚本
# 用法: ./generate-cert.sh [域名] [有效期天数]

DOMAIN=${1:-192.168.2.38}
DAYS=${2:-365}
KEY_FILE="server.key"
CERT_FILE="server.crt"

echo "正在生成自签名证书..."
echo "域名: $DOMAIN"
echo "有效期: $DAYS 天"

# 生成私钥和证书（一步完成）
openssl req -x509 -newkey rsa:4096 -keyout $KEY_FILE -out $CERT_FILE -days $DAYS -nodes \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=HarmonyOS/OU=WebServer/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:*.${DOMAIN},IP:192.168.2.38,IP:::1"

if [ $? -eq 0 ]; then
    echo "✅ 证书生成成功!"
    echo "私钥文件: $KEY_FILE"
    echo "证书文件: $CERT_FILE"
    
    # 显示证书信息
    echo ""
    echo "证书信息:"
    openssl x509 -in $CERT_FILE -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:|IP Address:)"
    
    # 设置文件权限
    chmod 600 $KEY_FILE
    chmod 644 $CERT_FILE
    
    echo ""
    echo "📋 使用方法:"
    echo "const tlsOptions = await CertificateManager.loadFromFiles('$KEY_FILE', '$CERT_FILE');"
else
    echo "❌ 证书生成失败"
    exit 1
fi