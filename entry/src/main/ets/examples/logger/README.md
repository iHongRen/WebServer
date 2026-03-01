# Logger Example

## Overview

This example demonstrates the WebServer framework's comprehensive logging capabilities. The framework supports multiple log formats, log levels, file storage, and detailed request/response tracking.

## Features

- ✅ Multiple log formats (dev, combined, common, short, tiny)
- ✅ Log level control (debug, info, warn, error)
- ✅ Automatic file storage
- ✅ Request/response time tracking
- ✅ Log statistics and analytics
- ✅ Log filtering by level and method
- ✅ Error tracking and reporting

## Quick Start

### 1. Start the Server

Run the LoggerPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8085`

### 2. Test with curl

```bash
# Get log records
curl http://192.168.2.38:8085/api/logs

# Get log statistics
curl http://192.168.2.38:8085/api/logs/stats

# Test error log
curl -X POST http://192.168.2.38:8085/api/logs/test/error \
  -H "Content-Type: application/json" \
  -d '{"message":"Test error"}'
```

### 3. Run Test Script

```bash
chmod +x test-logger-api.sh
./test-logger-api.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/logs` | Get log records (with filtering) |
| GET | `/api/logs/stats` | Get log statistics |
| DELETE | `/api/logs` | Clear all log records |
| POST | `/api/logs/test/:level` | Test log level (debug/info/warn/error) |
| GET | `/api/test/slow` | Slow request test |
| GET | `/api/test/error/:code` | Error status code test |

## Log Formats

### 1. Dev Format (Default)

Colorful, developer-friendly format with status indicators:

```
🟢 GET /api/users 200 15ms - 1024b
🟡 GET /api/redirect 302 5ms - 256b
🔴 POST /api/error 500 100ms - 512b
```

### 2. Combined Format

Apache combined log format:

```
192.168.1.100 - - [2024-01-01T00:00:00.000Z] "GET /api/users HTTP/1.1" 200 1024 "http://example.com" "Mozilla/5.0"
```

### 3. Common Format

Apache common log format:

```
192.168.1.100 - - [2024-01-01T00:00:00.000Z] "GET /api/users HTTP/1.1" 200 1024
```

### 4. Short Format

Concise format with essential information:

```
192.168.1.100 GET /api/users HTTP/1.1 200 1024 - 15ms
```

### 5. Tiny Format

Minimal format:

```
GET /api/users 200 1024 - 15ms
```

## Log Levels

### Debug

Detailed information for debugging:

```bash
curl -X POST http://IP:8085/api/logs/test/debug \
  -H "Content-Type: application/json" \
  -d '{"message":"Debug information"}'
```

### Info

General informational messages:

```bash
curl -X POST http://IP:8085/api/logs/test/info \
  -H "Content-Type: application/json" \
  -d '{"message":"Operation completed"}'
```

### Warn

Warning messages for potential issues:

```bash
curl -X POST http://IP:8085/api/logs/test/warn \
  -H "Content-Type: application/json" \
  -d '{"message":"Deprecated API used"}'
```

### Error

Error messages for failures:

```bash
curl -X POST http://IP:8085/api/logs/test/error \
  -H "Content-Type: application/json" \
  -d '{"message":"Operation failed"}'
```

## Log Query

### Get All Logs

```bash
curl http://IP:8085/api/logs
```

Response:
```json
{
  "logs": [...],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```

### Filter by Level

```bash
curl "http://IP:8085/api/logs?level=error"
```

### Filter by Method

```bash
curl "http://IP:8085/api/logs?method=POST"
```

### Pagination

```bash
curl "http://IP:8085/api/logs?limit=20&offset=40"
```

## Log Statistics

Get comprehensive statistics about logged requests:

```bash
curl http://IP:8085/api/logs/stats
```

Response:
```json
{
  "totalLogs": 150,
  "byLevel": {
    "debug": 20,
    "info": 100,
    "warn": 20,
    "error": 10
  },
  "byMethod": {
    "GET": 80,
    "POST": 50,
    "PUT": 15,
    "DELETE": 5
  },
  "byStatusCode": {
    "200": 120,
    "400": 10,
    "404": 15,
    "500": 5
  },
  "averageResponseTime": 45.5,
  "errorRate": 6.67
}
```

## Testing Features

### Slow Request Test

Test logging of slow requests:

```bash
# 1 second delay
curl "http://IP:8085/api/test/slow?delay=1000"

# 3 second delay
curl "http://IP:8085/api/test/slow?delay=3000"
```

### Error Status Code Test

Test logging of different error codes:

```bash
# 400 Bad Request
curl http://IP:8085/api/test/error/400

# 404 Not Found
curl http://IP:8085/api/test/error/404

# 500 Internal Server Error
curl http://IP:8085/api/test/error/500
```

## File Storage

Logs are automatically saved to the file system:

- **Location**: `{context.filesDir}/server.log`
- **Format**: Plain text, one line per log entry
- **Rotation**: Manual (clear via API)

## Code Example

```typescript
import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';

const server = new HttpServer();

// Enable logger middleware
server.logger({
  format: 'dev',  // or 'combined', 'common', 'short', 'tiny'
  stream: (log: string) => {
    console.log(log);
  }
});

// Custom logging in routes
server.get('/api/data', (req: HttpRequest, res: HttpResponse) => {
  // Log is automatically generated
  res.json({ data: 'example' });
});

await server.startServer(8085);
```

## Advanced Usage

### Custom Log Middleware

```typescript
server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
  const startTime = Date.now();
  
  res.onFinish((statusCode) => {
    const responseTime = Date.now() - startTime;
    console.log(`${req.method} ${req.path} - ${statusCode} - ${responseTime}ms`);
  });
  
  next();
});
```

### Log Level Filtering

Configure minimum log level:

```typescript
const loggerExample = new LoggerExample();
loggerExample.logLevel = 'warn';  // Only log warn and error
```

## Performance Tips

1. **Log Level**: Use appropriate log levels in production (info or warn)
2. **File Rotation**: Implement log rotation for long-running servers
3. **Async Logging**: File writes are asynchronous to avoid blocking
4. **Buffer Size**: Limit in-memory log records (default: 1000)

## Security Considerations

1. **Sensitive Data**: Don't log passwords, tokens, or sensitive information
2. **File Permissions**: Ensure log files have appropriate permissions
3. **Log Injection**: Sanitize user input before logging
4. **Storage Limits**: Monitor disk space usage

## Testing

The test script (`test-logger-api.sh`) includes comprehensive tests for:

- ✓ All log levels (debug, info, warn, error)
- ✓ Slow request logging
- ✓ Error status code logging
- ✓ Log query and filtering
- ✓ Log statistics
- ✓ Batch request logging
- ✓ Log clearing

## Troubleshooting

### Logs Not Appearing

1. Check log level configuration
2. Verify file write permissions
3. Check console output

### High Memory Usage

1. Reduce in-memory log buffer size
2. Implement log rotation
3. Clear old logs regularly

## References

- [Apache Log Format](https://httpd.apache.org/docs/current/logs.html)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [Logging Best Practices](https://www.loggly.com/ultimate-guide/node-logging-basics/)

