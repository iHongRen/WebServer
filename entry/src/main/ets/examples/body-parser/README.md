# Body Parser Example

## Overview

This example demonstrates the WebServer framework's automatic request body parsing capabilities. The framework supports multiple Content-Type formats and can automatically parse incoming request bodies based on the Content-Type header.

## Features

- ✅ JSON parsing (`application/json`)
- ✅ URL-encoded parsing (`application/x-www-form-urlencoded`)
- ✅ Multipart form parsing (`multipart/form-data`)
- ✅ Plain text parsing (`text/plain`)
- ✅ Automatic parser selection based on Content-Type
- ✅ Parse result tracking and management
- ✅ Error handling for invalid Content-Types

## Quick Start

### 1. Start the Server

Run the BodyPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8082`

### 2. Test with curl

```bash
# JSON parsing
curl -X POST http://192.168.2.38:8082/api/json \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":123}'

# URL-encoded parsing
curl -X POST http://192.168.2.38:8082/api/urlencoded \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=test&value=123"

# Multipart form parsing
curl -X POST http://192.168.2.38:8082/api/multipart \
  -F "name=test" \
  -F "file=@test.txt"
```

### 3. Run Test Script

```bash
chmod +x test-body-parser.sh
./test-body-parser.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/json` | Parse JSON data |
| POST | `/api/urlencoded` | Parse URL-encoded data |
| POST | `/api/multipart` | Parse multipart form data |
| POST | `/api/plain` | Parse plain text data |
| POST | `/api/auto` | Auto-detect and parse |
| GET | `/api/results` | Get parse results |
| GET | `/api/results/:id` | Get specific result |
| DELETE | `/api/results` | Clear all results |

## Parser Types

### 1. JSON Parser

Parses `application/json` content type.

```bash
curl -X POST http://IP:8082/api/json \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":30,"email":"john@example.com"}'
```

Response:
```json
{
  "message": "JSON解析成功",
  "parser": "JSON Parser",
  "contentType": "application/json",
  "result": {
    "id": 1,
    "type": "JSON",
    "data": {
      "name": "John",
      "age": 30,
      "email": "john@example.com"
    }
  }
}
```

### 2. URL-Encoded Parser

Parses `application/x-www-form-urlencoded` content type.

```bash
curl -X POST http://IP:8082/api/urlencoded \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=John&age=30&email=john@example.com"
```

Response:
```json
{
  "message": "URL编码解析成功",
  "parser": "URL-Encoded Parser",
  "contentType": "application/x-www-form-urlencoded",
  "result": {
    "id": 2,
    "type": "URL-Encoded",
    "data": {
      "name": "John",
      "age": "30",
      "email": "john@example.com"
    }
  }
}
```

### 3. Multipart Parser

Parses `multipart/form-data` content type (commonly used for file uploads).

```bash
curl -X POST http://IP:8082/api/multipart \
  -F "name=John" \
  -F "description=Test upload" \
  -F "file=@document.pdf"
```

Response:
```json
{
  "message": "多部分表单解析成功",
  "parser": "Multipart Parser",
  "contentType": "multipart/form-data; boundary=...",
  "result": {
    "id": 3,
    "type": "Multipart",
    "data": {
      "body": {
        "name": "John",
        "description": "Test upload"
      },
      "files": [
        {
          "fieldName": "file",
          "fileName": "document.pdf",
          "size": 102400,
          "contentType": "application/pdf"
        }
      ]
    }
  }
}
```

### 4. Plain Text Parser

Parses `text/plain` content type.

```bash
curl -X POST http://IP:8082/api/plain \
  -H "Content-Type: text/plain" \
  -d "This is plain text content"
```

Response:
```json
{
  "message": "纯文本解析成功",
  "parser": "Plain Text Parser",
  "contentType": "text/plain",
  "parsedData": "This is plain text content",
  "textLength": 26
}
```

### 5. Auto Parser

Automatically detects Content-Type and selects the appropriate parser.

```bash
# Auto-parse JSON
curl -X POST http://IP:8082/api/auto \
  -H "Content-Type: application/json" \
  -d '{"type":"auto-test"}'

# Auto-parse URL-encoded
curl -X POST http://IP:8082/api/auto \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "type=auto-test"
```

Response:
```json
{
  "message": "自动解析成功",
  "parser": "Auto Parser",
  "detectedType": "JSON (Auto)",
  "contentType": "application/json",
  "parsedData": {"type":"auto-test"},
  "hasFiles": false
}
```

## Result Management

### Get All Results

```bash
curl http://IP:8082/api/results
```

Response:
```json
{
  "results": [...],
  "total": 10,
  "limit": 20,
  "offset": 0,
  "totalParsed": 10,
  "byType": {
    "JSON": 3,
    "URL-Encoded": 2,
    "Multipart": 2,
    "Plain Text": 1,
    "JSON (Auto)": 2
  }
}
```

### Get Specific Result

```bash
curl http://IP:8082/api/results/1
```

### Clear All Results

```bash
curl -X DELETE http://IP:8082/api/results
```

## Code Example

```typescript
import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';

const server = new HttpServer();

// Enable JSON parser
server.json();

// Enable URL-encoded parser
server.urlencoded();

// Enable multipart parser
server.multipart();

// Enable plain text parser
server.plain();

// Or enable auto parser (detects Content-Type automatically)
server.auto();

// Handle parsed data
server.post('/api/data', (req: HttpRequest, res: HttpResponse) => {
  // Parsed data is available in req.body
  const data = req.body;
  
  // Files (if any) are in req.files
  const files = req.files;
  
  res.json({
    message: 'Data received',
    data: data,
    hasFiles: files ? Object.keys(files).length > 0 : false
  });
});

await server.startServer(8082);
```

## Error Handling

The server validates Content-Type headers and returns appropriate error messages:

```bash
# Wrong Content-Type for JSON endpoint
curl -X POST http://IP:8082/api/json \
  -H "Content-Type: text/plain" \
  -d "wrong type"
```

Response:
```json
{
  "error": "Content-Type must be application/json",
  "received": "text/plain"
}
```

## Testing

The test script (`test-body-parser.sh`) includes comprehensive tests for:

- ✓ JSON parsing
- ✓ URL-encoded parsing
- ✓ Multipart form parsing
- ✓ Plain text parsing
- ✓ Auto parser with different Content-Types
- ✓ Result management
- ✓ Error handling

## Performance Tips

1. **Parser Selection**: Use specific parsers when you know the Content-Type
2. **Auto Parser**: Use for flexible APIs that accept multiple formats
3. **File Size Limits**: Consider implementing size limits for multipart uploads
4. **Memory Management**: Large payloads are automatically handled by the framework

## Security Considerations

1. **Input Validation**: Always validate parsed data before use
2. **File Upload**: Validate file types and sizes in multipart requests
3. **Size Limits**: Implement appropriate payload size limits
4. **Content-Type Validation**: The framework validates Content-Type headers

## References

- [HTTP Content-Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type)
- [Multipart Form Data](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)
- [URL Encoding](https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding)

