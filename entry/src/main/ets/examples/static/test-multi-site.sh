#!/bin/bash

# 多站点静态文件服务器测试脚本
# 测试多个静态站点的功能

BASE_URL="http://127.0.0.1:8080"

echo "======================================"
echo "多站点静态文件服务器测试"
echo "======================================"
echo ""

# 测试主站点
echo "1. 测试主站点"
echo "GET ${BASE_URL}/"
curl -i "${BASE_URL}/" 2>/dev/null | head -20
echo ""
echo "---"
echo ""

# 测试主站点CSS
echo "2. 测试主站点CSS文件"
echo "GET ${BASE_URL}/css/style.css"
curl -i "${BASE_URL}/css/style.css" 2>/dev/null | head -15
echo ""
echo "---"
echo ""

# 测试主站点JSON
echo "3. 测试主站点JSON数据"
echo "GET ${BASE_URL}/data.json"
curl -s "${BASE_URL}/data.json" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/data.json"
echo ""
echo "---"
echo ""

# 测试站点1 - 文档中心
echo "4. 测试站点1 - 文档中心首页"
echo "GET ${BASE_URL}/site1/"
curl -i "${BASE_URL}/site1/" 2>/dev/null | head -20
echo ""
echo "---"
echo ""

# 测试站点1子页面
echo "5. 测试站点1 - 入门指南"
echo "GET ${BASE_URL}/site1/guides/getting-started.html"
curl -i "${BASE_URL}/site1/guides/getting-started.html" 2>/dev/null | head -15
echo ""
echo "---"
echo ""

# 测试站点2 - 图片画廊
echo "6. 测试站点2 - 图片画廊首页"
echo "GET ${BASE_URL}/site2/"
curl -i "${BASE_URL}/site2/" 2>/dev/null | head -20
echo ""
echo "---"
echo ""

# 测试站点2 JSON
echo "7. 测试站点2 - 画廊数据"
echo "GET ${BASE_URL}/site2/gallery.json"
curl -s "${BASE_URL}/site2/gallery.json" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/site2/gallery.json"
echo ""
echo "---"
echo ""

# 测试站点2目录浏览
echo "8. 测试站点2 - 目录浏览（photos目录）"
echo "GET ${BASE_URL}/site2/photos/"
curl -i "${BASE_URL}/site2/photos/" 2>/dev/null | head -25
echo ""
echo "---"
echo ""

# 测试站点3 - API文档
echo "9. 测试站点3 - API文档首页"
echo "GET ${BASE_URL}/site3/"
curl -i "${BASE_URL}/site3/" 2>/dev/null | head -20
echo ""
echo "---"
echo ""

# 测试站点3 OpenAPI
echo "10. 测试站点3 - OpenAPI v1规范"
echo "GET ${BASE_URL}/site3/v1/openapi.json"
curl -s "${BASE_URL}/site3/v1/openapi.json" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/site3/v1/openapi.json"
echo ""
echo "---"
echo ""

# 测试站点3目录浏览
echo "11. 测试站点3 - 目录浏览（v2目录）"
echo "GET ${BASE_URL}/site3/v2/"
curl -i "${BASE_URL}/site3/v2/" 2>/dev/null | head -25
echo ""
echo "---"
echo ""

# 测试站点管理API
echo "12. 测试站点管理API - 获取所有站点信息"
echo "GET ${BASE_URL}/api/sites"
curl -s "${BASE_URL}/api/sites" | python3 -m json.tool 2>/dev/null || curl -s "${BASE_URL}/api/sites"
echo ""
echo "---"
echo ""

# 测试缓存头
echo "13. 测试缓存控制 - 站点1（1小时缓存）"
echo "GET ${BASE_URL}/site1/"
curl -I "${BASE_URL}/site1/" 2>/dev/null | grep -i "cache-control\|etag"
echo ""
echo "---"
echo ""

echo "14. 测试缓存控制 - 站点2（2小时缓存）"
echo "GET ${BASE_URL}/site2/"
curl -I "${BASE_URL}/site2/" 2>/dev/null | grep -i "cache-control\|etag"
echo ""
echo "---"
echo ""

# 测试404
echo "15. 测试不存在的站点"
echo "GET ${BASE_URL}/site999/"
curl -i "${BASE_URL}/site999/" 2>/dev/null | head -10
echo ""
echo "---"
echo ""

echo "16. 测试站点内不存在的文件"
echo "GET ${BASE_URL}/site1/notfound.html"
curl -i "${BASE_URL}/site1/notfound.html" 2>/dev/null | head -10
echo ""
echo "---"
echo ""

echo "======================================"
echo "测试完成！"
echo "======================================"
