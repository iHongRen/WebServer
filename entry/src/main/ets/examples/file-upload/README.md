# 文件上传中间件示例

基于 express-fileupload 设计的流式文件上传中间件，支持高效的文件上传处理。

## 功能特性

- ✅ **流式处理**: 使用鸿蒙 `fs.createWriteStream` API 进行流式写入
- ✅ **多种格式支持**: 
  - `multipart/form-data` (表单文件上传)
  - `application/octet-stream` (二进制流上传)
- ✅ **临时文件管理**: 自动管理临时文件，提供 `mv()` 方法移动文件
- ✅ **文件限制**: 支持文件大小、数量、字段数量限制
- ✅ **安全处理**: 支持安全文件名处理、URI 解码
- ✅ **自动目录创建**: 可选的父目录自动创建功能

## 快速开始

### 1. 基本使用

```typescript
import { HttpServer, FileUpload } from '@cxy/webserver';
import type { UploadedFile } from '@cxy/webserver';

const server = new HttpServer();

// 添加文件上传中间件
server.post('/upload',
  FileUpload.create({
    tempFileDir: '/tmp/uploads',
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB
      files: 5
    }
  }),
  async (req, res) => {
    const file = req.files['file'] as UploadedFile;
    
    // 移动文件到目标位置
    await file.mv('/path/to/destination/' + file.name);
    
    res.json({
      success: true,
      file: {
        name: file.name,
        size: file.size,
        mimetype: file.mimetype
      }
    });
  }
);
```

### 2. 配置选项

```typescript
FileUpload.create({
  // 自动创建父目录
  createParentPath: true,
  
  // URI 解码文件名
  uriDecodeFileNames: true,
  
  // 安全文件名（移除特殊字符）
  safeFileNames: true,
  
  // 超过限制时中止
  abortOnLimit: true,
  
  // 临时文件目录
  tempFileDir: '/tmp/uploads',
  
  // 调试模式
  debug: true,
  
  // 文件限制
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB
    files: 10,                   // 最多10个文件
    fields: 100,                 // 最多100个字段
    fieldSize: 1024 * 1024       // 字段最大1MB
  }
})
```

## API 端点

### 上传接口

#### 1. 基本文件上传
```bash
POST /api/upload/basic
Content-Type: multipart/form-data

curl -X POST http://localhost:8080/api/upload/basic \
  -F "file=@test.jpg" \
  -F "description=测试文件"
```

#### 2. 流式上传
```bash
POST /api/upload/stream
Content-Type: application/octet-stream

curl -X POST http://localhost:8080/api/upload/stream \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@test.jpg"
```

#### 3. 多文件上传
```bash
POST /api/upload/multiple

curl -X POST http://localhost:8080/api/upload/multiple \
  -F "file1=@test1.jpg" \
  -F "file2=@test2.jpg" \
  -F "description=多文件测试"
```

#### 4. 安全文件名上传
```bash
POST /api/upload/safe

curl -X POST http://localhost:8080/api/upload/safe \
  -F "file=@test.jpg"
```

#### 5. 限制大小上传
```bash
POST /api/upload/limited

curl -X POST http://localhost:8080/api/upload/limited \
  -F "file=@small.jpg"
```

### 管理接口

#### 获取文件列表
```bash
GET /api/upload/files

curl http://localhost:8080/api/upload/files
```

#### 删除文件
```bash
DELETE /api/upload/files/:filename

curl -X DELETE http://localhost:8080/api/upload/files/test.jpg
```

## UploadedFile 接口

上传的文件会被解析为 `UploadedFile` 对象：

```typescript
interface UploadedFile {
  name: string;              // 原始文件名
  data: ArrayBuffer;         // 文件数据
  size: number;              // 文件大小（字节）
  encoding: string;          // 编码
  tempFilePath: string;      // 临时文件路径
  truncated: boolean;        // 是否被截断
  mimetype: string;          // MIME类型
  md5?: string;              // MD5哈希（可选）
  mv: (path: string) => Promise<void>; // 移动文件方法
}
```

### 使用示例

```typescript
// 获取上传的文件
const file = req.files['avatar'] as UploadedFile;

// 文件信息
console.log('文件名:', file.name);
console.log('大小:', file.size);
console.log('类型:', file.mimetype);
console.log('临时路径:', file.tempFilePath);

// 移动文件
await file.mv('/uploads/' + file.name);
```

## 测试

### 运行测试脚本

```bash
# 使用默认地址 (localhost:8080)
./test-file-upload.sh

# 指定服务器地址
./test-file-upload.sh http://192.168.1.100:8080
```

### 浏览器测试

启动服务器后，访问：
```
http://localhost:8080/upload.html
```

## 实现原理

### 1. 流式写入

使用鸿蒙的 `fs.createWriteStream` API 进行流式写入：

```typescript
const stream = fs.createWriteStream(filePath, {
  mode: fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC
});

await new Promise<void>((resolve, reject) => {
  stream.write(data, (err) => {
    if (err) {
      reject(err);
    } else {
      stream.close((closeErr) => {
        if (closeErr) reject(closeErr);
        else resolve();
      });
    }
  });
});
```

### 2. multipart/form-data 解析

- 解析 boundary 边界
- 分割数据块
- 提取文件和字段信息
- 流式写入临时文件

### 3. application/octet-stream 处理

- 直接将整个请求体作为文件数据
- 生成唯一文件名
- 流式写入临时文件

### 4. 文件移动

提供 `mv()` 方法：
- 复制临时文件到目标位置
- 删除临时文件
- 可选的父目录自动创建

## 与 express-fileupload 的对比

| 特性 | express-fileupload | 本实现 |
|------|-------------------|--------|
| 流式处理 | ✅ | ✅ |
| multipart/form-data | ✅ | ✅ |
| application/octet-stream | ❌ | ✅ |
| mv() 方法 | ✅ | ✅ |
| 临时文件管理 | ✅ | ✅ |
| 文件大小限制 | ✅ | ✅ |
| 安全文件名 | ✅ | ✅ |
| 自动创建目录 | ✅ | ✅ |

## 注意事项

1. **临时文件清理**: 使用 `mv()` 方法后会自动删除临时文件
2. **文件大小限制**: 默认限制 50MB，可通过配置调整
3. **并发上传**: 支持多文件并发上传
4. **错误处理**: 超过限制时可选择中止或继续
5. **内存占用**: 使用流式处理，内存占用低

## 最佳实践

### 1. 设置合理的限制

```typescript
FileUpload.create({
  limits: {
    fileSize: 10 * 1024 * 1024,  // 根据需求设置
    files: 5,                     // 限制文件数量
    fields: 50                    // 限制字段数量
  },
  abortOnLimit: true              // 超限时中止
})
```

### 2. 使用安全文件名

```typescript
FileUpload.create({
  safeFileNames: true,            // 移除特殊字符
  uriDecodeFileNames: true        // 解码文件名
})
```

### 3. 自动创建目录

```typescript
FileUpload.create({
  createParentPath: true          // 自动创建父目录
})
```

### 4. 错误处理

```typescript
server.post('/upload',
  FileUpload.create({ /* options */ }),
  async (req, res) => {
    try {
      const file = req.files['file'] as UploadedFile;
      await file.mv('/uploads/' + file.name);
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);
```

## 相关文档

- [鸿蒙文件系统 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fs)
- [express-fileupload](https://github.com/richardgirges/express-fileupload)
- [Busboy](https://github.com/fastify/busboy)

## 更新日志

### v1.0.0 (2025-03-03)
- ✨ 初始版本
- ✅ 支持 multipart/form-data
- ✅ 支持 application/octet-stream
- ✅ 流式写入使用 fs.createWriteStream
- ✅ 提供 mv() 方法
- ✅ 完整的配置选项
