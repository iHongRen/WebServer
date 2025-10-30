#!/bin/bash

# 生成完整证书链脚本（根CA + 中间CA + 服务器证书）
# 用法: ./generate-full-chain.sh [域名/IP] [有效期天数]

DOMAIN=${1:-192.168.2.38}
DAYS=${2:-365}

# 文件名
ROOT_CA_KEY="root-ca-key.pem"
ROOT_CA_CERT="root-ca-cert.pem"
INTERMEDIATE_CA_KEY="intermediate-ca-key.pem"
INTERMEDIATE_CA_CERT="intermediate-ca-cert.pem"
INTERMEDIATE_CA_CSR="intermediate-ca.csr"
SERVER_KEY="server-key.pem"
SERVER_CERT="server-cert.pem"
SERVER_CSR="server.csr"
CERT_CHAIN="cert-chain.pem"

echo "🏗️  生成完整证书链..."
echo "域名/IP: $DOMAIN"
echo "有效期: $DAYS 天"

# 创建配置文件
create_configs() {
    # 根CA配置
    cat > root-ca.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_ca

[dn]
C = CN
ST = Beijing
L = Beijing
O = HarmonyOS Root CA
OU = Certificate Authority
CN = HarmonyOS Root CA

[v3_ca]
basicConstraints = critical,CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

    # 中间CA配置
    cat > intermediate-ca.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_intermediate_ca

[dn]
C = CN
ST = Beijing
L = Beijing
O = HarmonyOS Intermediate CA
OU = Certificate Authority
CN = HarmonyOS Intermediate CA

[v3_intermediate_ca]
basicConstraints = critical,CA:true,pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

    # 服务器证书配置
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
OU = Development
CN = $DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
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

echo ""
echo "📋 步骤1: 生成根CA..."
create_configs

# 生成根CA私钥
openssl genrsa -out $ROOT_CA_KEY 4096

# 生成根CA证书
openssl req -new -x509 -days $((DAYS * 2)) -key $ROOT_CA_KEY -out $ROOT_CA_CERT -config root-ca.conf -extensions v3_ca

echo "✅ 根CA生成完成"

echo ""
echo "📋 步骤2: 生成中间CA..."

# 生成中间CA私钥
openssl genrsa -out $INTERMEDIATE_CA_KEY 4096

# 生成中间CA证书签名请求
openssl req -new -key $INTERMEDIATE_CA_KEY -out $INTERMEDIATE_CA_CSR -config intermediate-ca.conf

# 使用根CA签名中间CA证书
openssl x509 -req -in $INTERMEDIATE_CA_CSR -CA $ROOT_CA_CERT -CAkey $ROOT_CA_KEY -CAcreateserial \
    -out $INTERMEDIATE_CA_CERT -days $DAYS -extensions v3_intermediate_ca -extfile intermediate-ca.conf

echo "✅ 中间CA生成完成"

echo ""
echo "📋 步骤3: 生成服务器证书..."

# 生成服务器私钥
openssl genrsa -out $SERVER_KEY 4096

# 生成服务器证书签名请求
openssl req -new -key $SERVER_KEY -out $SERVER_CSR -config server.conf

# 使用中间CA签名服务器证书
openssl x509 -req -in $SERVER_CSR -CA $INTERMEDIATE_CA_CERT -CAkey $INTERMEDIATE_CA_KEY -CAcreateserial \
    -out $SERVER_CERT -days $DAYS -extensions v3_req -extfile server.conf

echo "✅ 服务器证书生成完成"

echo ""
echo "📋 步骤4: 创建证书链..."

# 创建完整证书链文件
cat $SERVER_CERT $INTERMEDIATE_CA_CERT $ROOT_CA_CERT > $CERT_CHAIN

echo "✅ 证书链创建完成"

# 验证证书链
echo ""
echo "🔍 验证证书链..."
openssl verify -CAfile $ROOT_CA_CERT -untrusted $INTERMEDIATE_CA_CERT $SERVER_CERT

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 完整证书链生成成功!"
    
    # 设置权限
    chmod 600 *key*.pem
    chmod 644 *cert*.pem $CERT_CHAIN
    
    # 清理临时文件
    rm -f *.conf *.csr *.srl
    
    echo ""
    echo "📁 生成的文件:"
    echo "  根CA私钥:     $ROOT_CA_KEY"
    echo "  根CA证书:     $ROOT_CA_CERT"
    echo "  中间CA私钥:   $INTERMEDIATE_CA_KEY"
    echo "  中间CA证书:   $INTERMEDIATE_CA_CERT"
    echo "  服务器私钥:   $SERVER_KEY"
    echo "  服务器证书:   $SERVER_CERT"
    echo "  完整证书链:   $CERT_CHAIN"
    
    echo ""
    echo "📋 使用方法:"
    echo "// 方式1: 使用单独的证书文件"
    echo "const tlsOptions = await CertificateManager.loadFromFiles("
    echo "  '$SERVER_KEY',"
    echo "  '$SERVER_CERT',"
    echo "  '$ROOT_CA_CERT'"
    echo ");"
    echo ""
    echo "// 方式2: 使用证书链文件"
    echo "const tlsOptions = await CertificateManager.loadFromFiles("
    echo "  '$SERVER_KEY',"
    echo "  '$CERT_CHAIN'"
    echo ");"
    
    echo ""
    echo "🔧 客户端配置:"
    echo "将 $ROOT_CA_CERT 添加到客户端的受信任根证书存储中"
    
else
    echo "❌ 证书链验证失败"
    exit 1
fi