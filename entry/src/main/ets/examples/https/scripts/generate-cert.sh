#!/bin/bash

# 创建完整的CA和服务器证书脚本
# 用法: ./generate-cert.sh [域名] [有效期天数] [是否生成CA]

DOMAIN=${1:-192.168.2.38}
DAYS=${2:-365}
GENERATE_CA=${3:-true}

# 文件名定义
CA_KEY="ca-key.pem"
CA_CERT="ca-cert.pem"
SERVER_KEY="server-key.pem"
SERVER_CERT="server-cert.pem"
SERVER_CSR="server.csr"

echo "🔐 开始生成证书链..."
echo "域名: $DOMAIN"
echo "有效期: $DAYS 天"
echo "生成CA: $GENERATE_CA"

# 创建证书配置文件
create_server_config() {
    cat > server.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = CN
ST = Beijing
L = Beijing
O = HarmonyOS WebServer
OU = Development Team
CN = $DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = localhost
DNS.3 = *.localhost
IP.1 = $DOMAIN
IP.2 = 127.0.0.1
IP.3 = ::1
EOF
}

if [ "$GENERATE_CA" = "true" ]; then
    echo ""
    echo "📋 步骤1: 生成CA根证书..."
    
    # 生成CA私钥
    echo "🔑 生成CA私钥..."
    openssl genrsa -out $CA_KEY 4096
    
    # 生成CA证书
    echo "📜 生成CA根证书..."
    openssl req -new -x509 -days $DAYS -key $CA_KEY -out $CA_CERT \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=HarmonyOS CA/OU=Certificate Authority/CN=HarmonyOS Root CA"
    
    if [ $? -ne 0 ]; then
        echo "❌ CA证书生成失败"
        exit 1
    fi
    
    echo "✅ CA证书生成成功: $CA_CERT"
fi

echo ""
echo "📋 步骤2: 生成服务器证书..."

# 生成服务器私钥
echo "🔑 生成服务器私钥..."
openssl genrsa -out $SERVER_KEY 4096

# 创建服务器证书配置
create_server_config

# 生成证书签名请求
echo "📄 生成证书签名请求..."
openssl req -new -key $SERVER_KEY -out $SERVER_CSR -config server.conf

if [ "$GENERATE_CA" = "true" ]; then
    # 使用CA签名服务器证书
    echo "✍️  使用CA签名服务器证书..."
    openssl x509 -req -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial \
        -out $SERVER_CERT -days $DAYS -extensions v3_req -extfile server.conf
else
    # 生成自签名服务器证书
    echo "✍️  生成自签名服务器证书..."
    openssl x509 -req -in $SERVER_CSR -signkey $SERVER_KEY -out $SERVER_CERT \
        -days $DAYS -extensions v3_req -extfile server.conf
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 证书生成完成!"
    
    # 显示生成的文件
    echo ""
    echo "📁 生成的文件:"
    if [ "$GENERATE_CA" = "true" ]; then
        echo "  CA私钥:     $CA_KEY"
        echo "  CA证书:     $CA_CERT"
    fi
    echo "  服务器私钥: $SERVER_KEY"
    echo "  服务器证书: $SERVER_CERT"
    
    # 显示证书信息
    echo ""
    echo "📋 服务器证书信息:"
    openssl x509 -in $SERVER_CERT -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:|IP Address:)"
    
    # 验证证书链
    if [ "$GENERATE_CA" = "true" ]; then
        echo ""
        echo "🔍 验证证书链:"
        openssl verify -CAfile $CA_CERT $SERVER_CERT
    fi
    
    # 设置文件权限
    chmod 600 *key*.pem
    chmod 644 *cert*.pem
    
    # 清理临时文件
    rm -f server.conf $SERVER_CSR
    
    echo ""
    echo "📋 使用方法:"
    if [ "$GENERATE_CA" = "true" ]; then
        echo "// 使用CA签名的证书"
        echo "const tlsOptions = await CertificateManager.loadFromFiles("
        echo "  '$SERVER_KEY',"
        echo "  '$SERVER_CERT',"
        echo "  '$CA_CERT'"
        echo ");"
    else
        echo "// 使用自签名证书"
        echo "const tlsOptions = await CertificateManager.loadFromFiles("
        echo "  '$SERVER_KEY',"
        echo "  '$SERVER_CERT'"
        echo ");"
    fi
    
    echo ""
    echo "🔧 客户端配置:"
    if [ "$GENERATE_CA" = "true" ]; then
        echo "将 $CA_CERT 添加到客户端的受信任根证书存储中"
    else
        echo "客户端需要忽略证书验证或手动信任 $SERVER_CERT"
    fi
    
else
    echo "❌ 服务器证书生成失败"
    rm -f server.conf $SERVER_CSR
    exit 1
fi