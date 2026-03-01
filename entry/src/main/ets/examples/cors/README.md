# CORS Example

## Overview

This example demonstrates Cross-Origin Resource Sharing (CORS) functionality in the WebServer framework. CORS is a security feature that allows or restricts web applications running at one origin to access resources from a different origin.

## Features

- ✅ Simple and preflight request handling
- ✅ Dynamic origin whitelist control
- ✅ Credentials (cookies) support
- ✅ Custom HTTP headers support
- ✅ CORS request logging and statistics
- ✅ Origin validation

## Quick Start

### 1. Start the Server

Run the CorsPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8083`

### 2. Test with curl

```bash
# Simple CORS request
curl -X GET http://192.168.2.38:8083/api/cors/simple \
  -H "Origin: http://example.com"

# Preflight request
curl -X OPTIONS http://192.168.2.38:8083/api/cors/preflight \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"

# Request with credentials
curl -X POST http://192.168.2.38:8083/api/cors/credentials \
  -H "Origin: http://example.com" \
  -H "Content-Type: application/json" \
  --cookie "session=abc123" \
  -d '{"test":"data"}'
```

### 3. Run Test Script

```bash
chmod +x test-cors.sh
./test-cors.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cors/simple` | Test simple CORS request |
| POST | `/api/cors/preflight` | Test preflight CORS request |
| POST | `/api/cors/credentials` | Test credentialed request |
| PUT | `/api/cors/custom-headers` | Test custom headers |
| GET | `/api/cors/config` | Get CORS configuration |
| POST | `/api/cors/test-origin` | Test if origin is allowed |

## How CORS Works

### Simple Requests

Simple requests are sent directly without a preflight check. They must meet these criteria:
- Method: GET, HEAD, or POST
- Headers: Only simple headers (Accept, Accept-Language, Content-Language, Content-Type)
- Content-Type: application/x-www-form-urlencoded, multipart/form-data, or text/plain

### Preflight Requests

For requests that don't meet simple request criteria, browsers send an OPTIONS request first:

```
OPTIONS /api/cors/preflight HTTP/1.1
Origin: http://example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type
```

Server responds with allowed methods and headers:

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
```

## Configuration

The example uses the following default CORS configuration:

```typescript
{
  corsOrigins: ['*'],  // Allow all origins
  corsMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  corsHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  corsCredentials: true
}
```

## Testing Different Scenarios

### 1. Test Simple Request

```bash
curl -X GET http://IP:8083/api/cors/simple \
  -H "Origin: http://localhost:3000" \
  -v
```

### 2. Test Preflight Request

```bash
curl -X POST http://IP:8083/api/cors/preflight \
  -H "Origin: http://localhost:3000" \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}' \
  -v
```

### 3. Test with Credentials

```bash
curl -X POST http://IP:8083/api/cors/credentials \
  -H "Origin: http://localhost:3000" \
  -H "Content-Type: application/json" \
  --cookie "session=test123" \
  -d '{"test":"data"}' \
  -v
```

### 4. Test Custom Headers

```bash
curl -X PUT http://IP:8083/api/cors/custom-headers \
  -H "Origin: http://localhost:3000" \
  -H "X-Custom-Header: custom-value" \
  -H "Authorization: Bearer token123" \
  -d '{"data":"test"}' \
  -v
```

## Common CORS Headers

### Request Headers

- `Origin`: The origin of the requesting site
- `Access-Control-Request-Method`: Method to be used in actual request
- `Access-Control-Request-Headers`: Headers to be used in actual request

### Response Headers

- `Access-Control-Allow-Origin`: Allowed origin(s)
- `Access-Control-Allow-Methods`: Allowed HTTP methods
- `Access-Control-Allow-Headers`: Allowed request headers
- `Access-Control-Allow-Credentials`: Whether credentials are allowed
- `Access-Control-Max-Age`: How long preflight results can be cached

## Troubleshooting

### CORS Error: "No 'Access-Control-Allow-Origin' header"

This means the server didn't include the required CORS header. Check:
1. CORS middleware is properly configured
2. Origin is in the allowed list
3. Server is responding to OPTIONS requests

### CORS Error: "Credentials flag is true, but Access-Control-Allow-Credentials is not"

When sending credentials (cookies), the server must explicitly allow it:
```typescript
server.cors({
  origin: 'http://specific-origin.com',  // Cannot be '*' with credentials
  credentials: true
});
```

## Security Considerations

1. **Avoid using `*` with credentials**: When allowing credentials, specify exact origins
2. **Validate origins**: Don't blindly trust the Origin header
3. **Limit allowed methods**: Only allow necessary HTTP methods
4. **Restrict headers**: Only allow required custom headers
5. **Set appropriate max-age**: Balance between performance and security

## Documentation

For detailed documentation in Chinese, see: [跨域中间件说明.md](./跨域中间件说明.md)

## References

- [MDN - CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [W3C CORS Specification](https://www.w3.org/TR/cors/)
- [CORS Best Practices](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#security)
