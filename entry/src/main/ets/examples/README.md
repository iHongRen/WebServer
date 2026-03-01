# WebServer Examples

本目录包含WebServer框架的完整示例集合，每个示例都展示了框架的特定功能。

## 📋 示例列表

### 1. HTTP Server (http/)
**端口**: 8080

基础HTTP服务器示例，展示完整的RESTful API和文件上传功能。

**主要功能**:
- ✅ 完整的CRUD操作
- ✅ 用户管理（分页、搜索）
- ✅ 文件上传和管理
- ✅ 静态文件服务
- ✅ 请求日志记录
- ✅ 错误处理
- ✅ CORS支持

**测试**: `./test-api.sh`

---

### 2. Body Parser (body-parser/)
**端口**: 8082

请求体解析示例，支持多种Content-Type自动解析。

**主要功能**:
- ✅ JSON解析 (`application/json`)
- ✅ URL编码解析 (`application/x-www-form-urlencoded`)
- ✅ 多部分表单解析 (`multipart/form-data`)
- ✅ 纯文本解析 (`text/plain`)
- ✅ 自动解析器（根据Content-Type自动选择）
- ✅ 解析结果跟踪和管理

**测试**: `./test-body-parser.sh`

---

### 3. CORS (cors/)
**端口**: 8083

跨域资源共享示例，展示CORS功能。

**主要功能**:
- ✅ 简单请求处理
- ✅ 预检请求（OPTIONS）
- ✅ 凭证请求（Cookies）
- ✅ 自定义HTTP头部
- ✅ 动态来源白名单
- ✅ CORS配置管理

**测试**: `./test-cors.sh`

---

### 4. Event (event/)
**端口**: 8084

服务器事件系统示例，展示事件监听和处理。

**主要功能**:
- ✅ 服务器生命周期事件（启动、停止）
- ✅ 客户端连接事件
- ✅ 客户端断开事件
- ✅ 错误事件捕获
- ✅ 实时事件监控
- ✅ 客户端管理

**测试**: `./test-event-api.sh`

---

### 5. Logger (logger/)
**端口**: 8085

日志记录示例，展示多种日志格式和级别控制。

**主要功能**:
- ✅ 多种日志格式（dev, combined, common, short, tiny）
- ✅ 日志级别控制（debug, info, warn, error）
- ✅ 文件日志存储
- ✅ 请求/响应时间跟踪
- ✅ 日志统计和分析
- ✅ 日志过滤和查询

**测试**: `./test-logger-api.sh`

---

### 6. Router (router/)
**端口**: 8086

路由系统示例，展示各种路由功能。

**主要功能**:
- ✅ 基础路由（GET, POST, PUT, DELETE）
- ✅ 参数路由（`/users/:id`, `/products/:category/:id`）
- ✅ 动态路由管理（运行时添加/删除）
- ✅ 路由统计和分析
- ✅ 请求跟踪
- ✅ 路由过滤和查询

**测试**: `./test-router-api.sh`

---

### 7. Static Files (static/)
**端口**: 8087

静态文件服务示例，展示文件服务功能。

**主要功能**:
- ✅ 静态文件服务（HTML, CSS, JS, JSON等）
- ✅ 文件浏览器
- ✅ 文件上传
- ✅ 文件删除
- ✅ MIME类型自动识别
- ✅ 缓存控制

**测试**: `./test-static-api.sh`

---

### 8. Upload (upload/)
**端口**: 8088

分片上传示例，展示大文件上传功能。

**主要功能**:
- ✅ 分片上传（将大文件分割上传）
- ✅ 断点续传
- ✅ 并发上传
- ✅ MD5完整性校验
- ✅ 进度跟踪
- ✅ 任务管理
- ✅ Web测试界面

**测试**: `./test-upload.sh`  
**Web界面**: `http://IP:8088/chunk-upload.html`

---

### 9. Stream (stream/)
**端口**: 8089

流式传输示例，展示分块传输功能。

**主要功能**:
- ✅ 流式文本传输
- ✅ Server-Sent Events (SSE)
- ✅ 大数据流传输
- ✅ 文件流传输
- ✅ 实时日志流
- ✅ 进度报告流

**测试**: `./test-stream.sh`

---

### 10. Stream Upload (stream-upload/)
**端口**: 8087

流式上传示例，展示接收流式上传数据。

**主要功能**:
- ✅ 接收流式文本数据
- ✅ 接收流式JSON数据
- ✅ 接收流式文件上传
- ✅ 大文件流式上传
- ✅ 自动分块解码
- ✅ Transfer-Encoding: chunked支持

**测试**: `./test-stream-upload.sh`

---

### 11. HTTPS (https/)
**端口**: 8443

HTTPS/TLS安全连接示例。

**主要功能**:
- ✅ TLS加密连接
- ✅ SSL证书管理
- ✅ 自签名证书支持
- ✅ CA证书支持
- ✅ 安全API端点
- ✅ 客户端证书验证

**测试**: `./test-https-api.sh`  
**证书生成**: `./scripts/generate-dev-cert.sh`

---

## 🚀 快速开始

### 1. 启动示例

在HarmonyOS应用中运行对应的Page组件，点击"启动服务器"按钮。

### 2. 测试示例

每个示例都提供了测试脚本：

```bash
cd entry/src/main/ets/examples/<example-name>
chmod +x test-*.sh
./test-*.sh
```

### 3. 查看文档

每个示例目录都包含详细的README.md文档。

## 📝 示例结构

每个示例都遵循统一的结构：

```
example-name/
├── ExampleName.ets          # 服务器实现
├── ExamplePage.ets          # UI页面
├── README.md                # 英文文档
├── test-*.sh                # 测试脚本
└── *.md                     # 其他文档（可选）
```

## 🎯 示例特点

所有示例都包含：

1. **服务器控制**: 启动/停止按钮，端口配置
2. **功能说明**: 详细的功能描述和图标
3. **API端点**: 完整的API列表和说明
4. **测试方法**: curl命令示例
5. **测试脚本**: 自动化测试脚本
6. **详细文档**: README.md文档

## 🔧 通用功能

所有示例都支持：

- ✅ 动态端口配置
- ✅ 服务器地址显示（使用实际IP）
- ✅ 日志记录
- ✅ CORS支持
- ✅ 错误处理
- ✅ 自动化测试

## 📚 学习路径

推荐的学习顺序：

1. **HTTP Server** - 了解基础功能
2. **Body Parser** - 学习请求解析
3. **Router** - 掌握路由系统
4. **Logger** - 理解日志记录
5. **Static Files** - 学习文件服务
6. **CORS** - 了解跨域处理
7. **Event** - 掌握事件系统
8. **Stream** - 学习流式传输
9. **Upload** - 掌握文件上传
10. **Stream Upload** - 学习流式上传
11. **HTTPS** - 了解安全连接

## 🛠️ 开发工具

### 测试工具

- **curl**: HTTP请求测试
- **jq**: JSON数据格式化
- **openssl**: SSL证书生成和测试

### 安装工具

```bash
# macOS
brew install curl jq openssl

# Linux
apt-get install curl jq openssl
```

## 📖 相关文档

- [WebServer框架文档](../../README.md)
- [API参考](../../docs/API.md)
- [最佳实践](../../docs/BEST_PRACTICES.md)

## 🤝 贡献

欢迎提交新的示例或改进现有示例！

## 📄 许可证

所有示例代码遵循项目主许可证。

---

**注意**: 所有示例都使用服务器返回的实际IP地址，而不是硬编码的IP。这使得示例可以在不同的网络环境中正常工作。
