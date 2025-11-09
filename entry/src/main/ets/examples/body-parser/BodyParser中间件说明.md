# BodyParser 中间件使用指南

## 1. 概述

`BodyParser` 是一个功能强大的中间件，用于解析 HTTP 请求的请求体 (request body)。在处理 `POST`、`PUT`、`PATCH` 等包含数据的请求时，这个中间件会自动将请求体中的数据转换成 JavaScript 对象，并附加到 `HttpRequest` 对象的 `body` 或 `files` 属性上，方便开发者直接使用。

`WebServer` 框架内置了对 `BodyParser` 的支持，并为不同类型的数据格式提供了独立的解析器。

## 2.核心功能

- **JSON 解析**: 解析 `application/json` 格式的请求体。
- **URL-Encoded 解析**: 解析 `application/x-www-form-urlencoded` 格式的表单数据。
- **Multipart 解析**: 解析 `multipart/form-data` 格式的表单数据，常用于文件上传。
- **纯文本解析**: 解析 `text/plain` 格式的请求体为字符串。
- **自动解析**: 根据请求头 `Content-Type` 自动选择合适的解析器。

## 3. 如何使用

你可以根据需要，在你的 `HttpServer` 实例上启用一个或多个解析器。

### 3.1. 启用特定的解析器

推荐为不同的路由或整个服务器启用你需要的特定解析器。这样做更高效，也更安全。

```typescript
import { HttpServer } from "@cxy/webserver";

const server = new HttpServer();

// 启用 JSON 解析器
server.json();

// 启用 URL-Encoded 解析器
server.urlencoded();

// 启用 Multipart 解析器 (用于文件上传)
server.multipart({ dest: '/path/to/your/uploads' }); // 'dest' 是可选的，用于指定文件上传目录

// 启用纯文本解析器
server.plain();

// 定义一个路由来处理 JSON 数据
server.post('/api/data', (req, res) => {
  // 如果请求的 Content-Type 是 application/json,
  // req.body 将会是一个 JavaScript 对象
  console.log('收到的数据:', req.body);
  res.json({ message: '数据接收成功', data: req.body });
});

server.startServer(8080);
```

### 3.2. 启用自动解析器

如果你希望服务器能自动处理多种不同类型的请求体，可以使用 `auto()` 方法。它会根据 `Content-Type` 自动选择解析器。

```typescript
import { HttpServer } from "@cxy/webserver";

const server = new HttpServer();

// 启用自动解析器
server.auto();

server.post('/api/submit', (req, res) => {
  // req.body 会根据 Content-Type 被解析
  // 例如, application/json -> object
  // application/x-www-form-urlencoded -> object
  // text/plain -> string
  console.log('自动解析后的数据:', req.body);
  res.json({ message: '数据已提交', body: req.body });
});

server.startServer(8080);
```

**注意**: `auto()` 方法非常方便，但它会为所有路由启用所有类型的解析器。对于大型应用，建议使用特定的解析器以获得更好的性能和控制。

## 4. API 测试示例 (`curl`)

以下是使用 `curl` 测试 `BodyParser` 功能的示例。请将 `http://your-ip:8082` 替换为你的服务器实际地址和端口。

### 4.1. 测试 JSON 解析 (`/api/json`)

```bash
curl -X POST http://your-ip:8082/api/json \
  -H "Content-Type: application/json" \
  -d '{"username": "cxy", "level": 99}'
```

**预期响应:**
```json
{
  "message": "JSON解析成功",
  "parser": "JSON Parser",
  "contentType": "application/json",
  "result": {
    "id": 1,
    "type": "JSON",
    "contentType": "application/json",
    "data": {
      "username": "cxy",
      "level": 99
    },
    "timestamp": "..."
  }
}
```

### 4.2. 测试 URL-Encoded 解析 (`/api/urlencoded`)

```bash
curl -X POST http://your-ip:8082/api/urlencoded \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'product=WebServer&version=1.0'
```

**预期响应:**
```json
{
  "message": "URL编码解析成功",
  "parser": "URL-Encoded Parser",
  "contentType": "application/x-www-form-urlencoded",
  "result": {
    "id": 2,
    "type": "URL-Encoded",
    "contentType": "application/x-www-form-urlencoded",
    "data": {
      "product": "WebServer",
      "version": "1.0"
    },
    "timestamp": "..."
  }
}
```

### 4.3. 测试 Multipart (文件上传) 解析 (`/api/multipart`)

```bash
# 1. 创建一个测试文件
echo "This is a test file for upload." > test.txt

# 2. 发送 multipart/form-data 请求
curl -X POST http://your-ip:8082/api/multipart \
  -F "description=This is a file upload test" \
  -F "testFile=@test.txt"
```

**预期响应:**
```json
{
  "message": "多部分表单解析成功",
  "parser": "Multipart Parser",
  "contentType": "multipart/form-data; boundary=...",
  "result": {
    "id": 3,
    "type": "Multipart",
    "contentType": "multipart/form-data; boundary=...",
    "data": {
      "body": {
        "description": "This is a file upload test"
      },
      "files": [
        {
          "fieldName": "testFile",
          "fileName": "test.txt",
          "size": 32,
          "contentType": "text/plain"
        }
      ]
    },
    "timestamp": "..."
  }
}
```

### 4.4. 测试纯文本解析 (`/api/plain`)

```bash
curl -X POST http://your-ip:8082/api/plain \
  -H "Content-Type: text/plain" \
  -d 'Hello, WebServer!'
```

**预期响应:**
```json
{
  "message": "纯文本解析成功",
  "parser": "Plain Text Parser",
  "contentType": "text/plain",
  "parsedData": "Hello, WebServer!",
  "textLength": 17,
  "result": {
    "id": 4,
    "type": "Plain Text",
    "contentType": "text/plain",
    "data": "Hello, WebServer!",
    "timestamp": "..."
  }
}
```

## 5. 访问解析后的数据

- **普通数据**: 解析后的键值对数据（来自 JSON 或 URL-Encoded）会被放入 `req.body` 对象。
- **文件数据**: 上传的文件信息（来自 Multipart）会被放入 `req.files` 对象。`req.files` 是一个对象，其中键是表单中 `input` 元素的 `name`，值是文件对象。
- **纯文本**: 解析后的字符串会直接成为 `req.body`。

通过学习本指南，你应该能够快速上手并有效利用 `BodyParser` 中间件来处理各种客户端请求。