# Stream Upload Example

## Overview

This example demonstrates how the WebServer framework handles streaming uploads using `Transfer-Encoding: chunked`. Streaming uploads allow clients to send data in chunks without knowing the total content length upfront, making it ideal for large file uploads and real-time data transmission.

## Features

- ✅ Automatic chunked transfer encoding detection
- ✅ Automatic chunk decoding and data merging
- ✅ Support for text, JSON, and binary data
- ✅ Large file upload support
- ✅ File management (list uploaded files)
- ✅ Real-time data streaming

## Quick Start

### 1. Start the Server

Run the StreamUploadPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8087`

### 2. Test with curl

```bash
# Stream text upload
curl -X POST http://192.168.2.38:8087/api/upload/stream-text \
  -H "Transfer-Encoding: chunked" \
  -d "Hello, Streaming Upload!"

# Stream JSON upload
curl -X POST http://192.168.2.38:8087/api/upload/stream-json \
  -H "Transfer-Encoding: chunked" \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":123}'

# Stream file upload
curl -X POST http://192.168.2.38:8087/api/upload/stream-file?filename=test.txt \
  -H "Transfer-Encoding: chunked" \
  --data-binary @file.txt
```

### 3. Run Test Script

```bash
chmod +x test-stream-upload.sh
./test-stream-upload.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/upload/stream-text` | Stream text data upload |
| POST | `/api/upload/stream-json` | Stream JSON data upload |
| POST | `/api/upload/stream-file` | Stream file upload |
| POST | `/api/upload/stream-large` | Large file stream upload |
| GET | `/api/upload/files` | List uploaded files |

## How It Works

### Client Side

When using `Transfer-Encoding: chunked`, the client sends data in the following format:

```
POST /api/upload HTTP/1.1
Transfer-Encoding: chunked

5\r\n
Hello\r\n
6\r\n
 World\r\n
0\r\n
\r\n
```

Each chunk consists of:
1. Chunk size in hexadecimal + `\r\n`
2. Chunk data + `\r\n`
3. Final chunk with size 0 indicates end of transmission

### Server Side

The WebServer framework automatically:

1. **Detects chunked encoding** in `HttpServer.isRequestComplete()`
   - Checks for `Transfer-Encoding: chunked` header
   - Waits for complete chunked data (until `0\r\n\r\n`)

2. **Decodes chunks** in `HttpRequest.parseBody()`
   - Parses chunk sizes
   - Extracts chunk data
   - Merges all chunks into complete body

3. **Provides unified API**
   - Access decoded data via `req.body`
   - Access raw data via `req.getRawBody()`
   - Check if chunked via `req.get('transfer-encoding')`

## Code Example

```typescript
import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';

const server = new HttpServer();

server.post('/api/upload', async (req: HttpRequest, res: HttpResponse) => {
  // Check if request used chunked encoding
  const isChunked = req.get('transfer-encoding')?.includes('chunked');
  
  // Get decoded body (framework handles chunk decoding)
  const data = req.body;
  
  // Or get raw ArrayBuffer
  const rawData = req.getRawBody();
  
  res.json({
    success: true,
    isChunked: isChunked,
    receivedSize: rawData.byteLength
  });
});

await server.startServer(8087);
```

## Use Cases

### 1. Large File Upload

Stream large files without loading entire content into memory:

```bash
curl -X POST http://IP:8087/api/upload/stream-large \
  -H "Transfer-Encoding: chunked" \
  --data-binary @large-file.bin
```

### 2. Real-time Data Streaming

Upload real-time generated data:

```bash
# Stream log data
tail -f app.log | curl -X POST http://IP:8087/api/upload/stream-text \
  -H "Transfer-Encoding: chunked" \
  --data-binary @-
```

### 3. Dynamic Content

Upload dynamically generated content with unknown size:

```bash
# Compress and upload on-the-fly
tar czf - /path/to/dir | curl -X POST http://IP:8087/api/upload/stream-file \
  -H "Transfer-Encoding: chunked" \
  --data-binary @-
```

## Performance Tips

1. **Chunk Size**: Balance between 64KB-256KB for optimal performance
2. **Memory Management**: Framework automatically manages buffers
3. **Error Handling**: Implement proper timeout and retry mechanisms
4. **File Streaming**: Save directly to disk for large uploads

## Comparison with Regular Upload

| Feature | Regular Upload | Streaming Upload |
|---------|---------------|------------------|
| Content Size | Must be known | Can be unknown |
| Memory Usage | Full buffering | Progressive processing |
| Real-time | Wait for complete data | Process as received |
| Use Case | Small files | Large files, streams |

## Testing

The test script (`test-stream-upload.sh`) includes:

- ✓ Stream text upload
- ✓ Stream JSON upload
- ✓ Stream file upload
- ✓ Large file upload (1MB)
- ✓ File list query
- ✓ Chunked encoding verification
- ✓ Large data upload (1000 lines)

## Documentation

For detailed documentation in Chinese, see: [流式上传使用指南.md](./流式上传使用指南.md)

## References

- [RFC 9112 - HTTP/1.1 Chunked Transfer Coding](https://www.rfc-editor.org/rfc/rfc9112.html#name-chunked-transfer-coding)
- [MDN - Transfer-Encoding](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding)
- [HarmonyOS HTTP Documentation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/http)
