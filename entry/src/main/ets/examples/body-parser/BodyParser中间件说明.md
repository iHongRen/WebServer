# Body-Parser中间件说明

## 概述

`Body-Parser` 中间件用于解析传入请求的请求体。它支持 `JSON`、`URL-encoded` 和 `text` 格式。

## 基本使用

```typescript
import { HttpServer, BodyParser } from "@cxy/webserver";

const server = new HttpServer();

// 使用bodyParser中间件
server.use(bodyParser());

server.post('/api/users', (req, res) => {
  // req.body 中包含了已解析的请求体
  const user = req.body;
  res.json({ message: '用户已创建', user });
});

server.startServer(8080)
```

## 支持的Content-Type

`Body-Parser` 会根据请求的 `Content-Type` 头自动选择解析器：

- `application/json`: 解析为JSON对象。
- `application/x-www-form-urlencoded`: 解析为键值对对象。
- `application/multipart/form-data`: 解析多部分表单数据。
- `text/plain`: 解析为字符串。

如果 `Content-Type` 不匹配或缺失，`req.body` 将为原始对象 。

## curl` 测试用例

### 测试JSON解析

```bash
curl -X POST http://your-ip:8080/json-test \
  -H "Content-Type: application/json" \
  -d '{"name": "cxy", "age": 30}'
```

**预期响应:**

```json
{
  "message": "收到JSON数据",
  "data": {
    "name": "cxy",
    "age": 30
  }
}
```

### 测试URL编码解析

```bash
curl -X POST http://your-ip:8080/urlencoded-test \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'name=cxy&city=Shanghai'
```

**预期响应:**

```json
{
  "message": "收到URL编码数据",
  "data": {
    "name": "cxy",
    "city": "Shanghai"
  }
}
```

### 测试文本解析

```bash
curl -X POST http://your-ip:8080/text-test \
  -H "Content-Type: text/plain" \
  -d 'Hello World'
```

**预期响应:**

```
收到文本数据: Hello World
```

### 测试multipart/form-data解析

假设有一个用于文件上传的路由 `/api/upload`。

```bash
# 创建一个示例文本文件
_`echo "This is a test file." > test.txt`_

# 发送包含文本字段和文件的请求
curl -X POST http://your-ip:8080/api/upload \
  -F "fieldName=someValue" \
  -F "uploadFile=@test.txt"
```

**预期响应:**

响应内容会根据服务器端的具体实现而变化，但通常会包含上传成功的信息和文件详情。

```json
{
  "message": "File uploaded successfully!",
  "filename": "test.txt",
  "size": 20,
  "contentType": "text/plain",
  "savedTo": "/path/to/saved/file/test.txt"
}
```

