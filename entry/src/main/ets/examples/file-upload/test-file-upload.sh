#!/bin/bash

# 文件上传中间件测试脚本
# 使用方法: ./test-file-upload.sh [服务器地址]

SERVER=${1:-"http://192.168.2.74:8080"}

echo "========================================="
echo "文件上传中间件测试"
echo "服务器地址: $SERVER"
echo "========================================="
echo ""

# 创建测试文件
echo "创建测试文件..."
echo "This is a test file for upload" > test.txt
echo "Hello, World!" > test2.txt
dd if=/dev/zero of=large.bin bs=1M count=2 2>/dev/null
echo "✓ 测试文件创建完成"
echo ""

# 测试1: 基本文件上传 (multipart/form-data)
echo "测试1: 基本文件上传"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/basic" \
  -F "file=@test.txt" \
  -F "description=测试文件" \
  -F "author=测试用户"
echo ""
echo ""

# 测试2: 流式上传 (application/octet-stream)
echo "测试2: 流式上传 (application/octet-stream)"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/stream" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@test.txt"
echo ""
echo ""

# 测试3: 多文件上传
echo "测试3: 多文件上传"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/multiple" \
  -F "file1=@test.txt" \
  -F "file2=@test2.txt" \
  -F "description=多文件测试"
echo ""
echo ""

# 测试4: 安全文件名上传
echo "测试4: 安全文件名上传"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/safe" \
  -F "file=@test.txt" \
  -F "name=测试文件.txt"
echo ""
echo ""

# 测试5: 大文件上传
echo "测试5: 大文件上传 (2MB)"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/basic" \
  -F "file=@large.bin" \
  -F "description=大文件测试"
echo ""
echo ""

# 测试6: 超过限制的上传 (应该失败)
echo "测试6: 超过限制的上传 (应该失败)"
echo "-----------------------------------"
curl -X POST "$SERVER/api/upload/limited" \
  -F "file=@large.bin"
echo ""
echo ""

# 测试7: 获取文件列表
echo "测试7: 获取文件列表"
echo "-----------------------------------"
curl -X GET "$SERVER/api/upload/files"
echo ""
echo ""

# 测试8: 删除文件
echo "测试8: 删除文件"
echo "-----------------------------------"
# 首先获取文件列表，然后删除第一个文件
FILE_TO_DELETE=$(curl -s "$SERVER/api/upload/files" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$FILE_TO_DELETE" ]; then
  echo "删除文件: $FILE_TO_DELETE"
  curl -X DELETE "$SERVER/api/upload/files/$FILE_TO_DELETE"
  echo ""
else
  echo "没有文件可删除"
fi
echo ""

# 清理测试文件
echo "清理测试文件..."
rm -f test.txt test2.txt large.bin
echo "✓ 测试文件清理完成"
echo ""

echo "========================================="
echo "测试完成!"
echo "========================================="
