# Router Example

## Overview

This example demonstrates the WebServer framework's powerful routing system. The framework supports basic routes, parameterized routes, dynamic route management, and comprehensive route tracking and analytics.

## Features

- ✅ Basic HTTP method routing (GET, POST, PUT, DELETE)
- ✅ Parameterized routes (`/users/:id`, `/products/:category/:id`)
- ✅ Dynamic route management (add/remove routes at runtime)
- ✅ Route statistics and analytics
- ✅ Request tracking and logging
- ✅ Route filtering and querying

## Quick Start

### 1. Start the Server

Run the RouterPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8080`

### 2. Test with curl

```bash
# Basic route
curl http://192.168.2.38:8080/

# Parameterized route
curl http://192.168.2.38:8080/api/users/123

# Route statistics
curl http://192.168.2.38:8080/api/routes/stats
```

### 3. Run Test Script

```bash
chmod +x test-router-api.sh
./test-router-api.sh
```

## API Endpoints

### Basic Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Homepage |
| GET | `/about` | About page |
| GET | `/contact` | Contact page |

### Parameterized Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/:id` | Get user by ID |
| GET | `/api/products/:category/:id` | Get product by category and ID |
| GET | `/api/posts/:id` | Get post by ID (supports format query) |

### Route Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/routes/stats` | Get route statistics |
| GET | `/api/routes/records` | Get route access records |
| POST | `/api/routes` | Add dynamic route |
| GET | `/api/routes/dynamic` | Get all dynamic routes |
| DELETE | `/api/routes/:method/:path` | Delete dynamic route |
| DELETE | `/api/routes/records` | Clear route records |

## Route Types

### 1. Basic Routes

Simple routes with fixed paths:

```bash
# Homepage
curl http://IP:8080/

# About page
curl http://IP:8080/about

# Contact page
curl http://IP:8080/contact
```

Response:
```json
{
  "page": "About",
  "message": "这是关于页面",
  "version": "1.0.1",
  "features": ["基础路由", "路由参数", "路由管理"]
}
```

### 2. Single Parameter Routes

Routes with one parameter:

```bash
curl http://IP:8080/api/users/123
```

Response:
```json
{
  "route": "/api/users/:id",
  "userId": "123",
  "name": "User 123",
  "email": "user123@example.com",
  "params": {
    "id": "123"
  }
}
```

### 3. Multiple Parameter Routes

Routes with multiple parameters:

```bash
curl http://IP:8080/api/products/electronics/456
```

Response:
```json
{
  "route": "/api/products/:category/:id",
  "category": "electronics",
  "productId": "456",
  "name": "Product 456",
  "price": 599,
  "params": {
    "category": "electronics",
    "id": "456"
  }
}
```

### 4. Routes with Query Parameters

Routes that support query parameters:

```bash
# JSON format (default)
curl http://IP:8080/api/posts/789?format=json

# XML format
curl http://IP:8080/api/posts/789?format=xml
```

JSON Response:
```json
{
  "id": "789",
  "title": "Post 789",
  "content": "This is the content of post 789",
  "author": "Admin",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

XML Response:
```xml
<?xml version="1.0"?>
<post>
  <id>789</id>
  <title>Post 789</title>
  <content>This is the content of post 789</content>
  <author>Admin</author>
  <createdAt>2024-01-01T00:00:00.000Z</createdAt>
</post>
```

## Dynamic Route Management

### Add Dynamic Route

Create routes at runtime:

```bash
curl -X POST http://IP:8080/api/routes \
  -H "Content-Type: application/json" \
  -d '{
    "method": "GET",
    "path": "/api/custom",
    "response": {
      "message": "This is a dynamic route",
      "timestamp": "2024-01-01T00:00:00.000Z"
    }
  }'
```

Response:
```json
{
  "message": "Dynamic route added",
  "routeKey": "GET:/api/custom",
  "totalDynamicRoutes": 1
}
```

### Access Dynamic Route

```bash
curl http://IP:8080/api/custom
```

Response:
```json
{
  "message": "动态路由响应",
  "route": "/api/custom",
  "method": "GET",
  "config": {
    "method": "GET",
    "path": "/api/custom",
    "response": {...},
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### List Dynamic Routes

```bash
curl http://IP:8080/api/routes/dynamic
```

Response:
```json
{
  "dynamicRoutes": [
    ["GET:/api/custom", {...}],
    ["POST:/api/test", {...}]
  ],
  "count": 2
}
```

### Delete Dynamic Route

```bash
curl -X DELETE http://IP:8080/api/routes/GET/api/custom
```

Response:
```json
{
  "message": "Dynamic route deleted",
  "routeKey": "GET:/api/custom",
  "deleted": true,
  "remainingRoutes": 1
}
```

## Route Statistics

Get comprehensive statistics about route usage:

```bash
curl http://IP:8080/api/routes/stats
```

Response:
```json
{
  "totalRequests": 150,
  "routeStats": {
    "GET /": 20,
    "GET /api/users/:id": 50,
    "GET /api/products/:category/:id": 30,
    "POST /api/routes": 10
  },
  "methodStats": {
    "GET": 120,
    "POST": 20,
    "PUT": 5,
    "DELETE": 5
  },
  "averageResponseTime": 12.5,
  "popularRoutes": [
    {"route": "GET /api/users/:id", "count": 50},
    {"route": "GET /api/products/:category/:id", "count": 30}
  ],
  "recentRequests": [...]
}
```

## Route Records

### Get All Records

```bash
curl http://IP:8080/api/routes/records
```

Response:
```json
{
  "records": [
    {
      "id": 1,
      "method": "GET",
      "path": "/api/users/123",
      "pattern": "/api/users/:id",
      "params": {"id": "123"},
      "query": "{}",
      "timestamp": "2024-01-01T00:00:00.000Z",
      "responseTime": 15,
      "statusCode": 200
    }
  ],
  "total": 100,
  "limit": 50,
  "offset": 0
}
```

### Filter by Method

```bash
curl "http://IP:8080/api/routes/records?method=POST"
```

### Pagination

```bash
curl "http://IP:8080/api/routes/records?limit=20&offset=40"
```

### Clear Records

```bash
curl -X DELETE http://IP:8080/api/routes/records
```

## Code Example

```typescript
import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';

const server = new HttpServer();

// Basic route
server.get('/', (req: HttpRequest, res: HttpResponse) => {
  res.json({ message: 'Homepage' });
});

// Single parameter route
server.get('/users/:id', (req: HttpRequest, res: HttpResponse) => {
  const userId = req.params['id'];
  res.json({ userId, name: `User ${userId}` });
});

// Multiple parameter route
server.get('/products/:category/:id', (req: HttpRequest, res: HttpResponse) => {
  const { category, id } = req.params;
  res.json({ category, productId: id });
});

// Route with query parameters
server.get('/search', (req: HttpRequest, res: HttpResponse) => {
  const query = req.query.get('q');
  const page = req.query.get('page') || '1';
  res.json({ query, page });
});

await server.startServer(8080);
```

## Advanced Usage

### Route Middleware

Apply middleware to specific routes:

```typescript
// Authentication middleware
const authMiddleware = (req: HttpRequest, res: HttpResponse, next: NextFunction) => {
  const token = req.get('authorization');
  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  next();
};

// Protected route
server.get('/api/protected', authMiddleware, (req, res) => {
  res.json({ message: 'Protected data' });
});
```

### Route Groups

Organize routes by prefix:

```typescript
// API v1 routes
server.get('/api/v1/users', handler);
server.get('/api/v1/products', handler);

// API v2 routes
server.get('/api/v2/users', handler);
server.get('/api/v2/products', handler);
```

## Performance Tips

1. **Route Order**: Define specific routes before generic ones
2. **Parameter Validation**: Validate parameters early in the handler
3. **Caching**: Cache frequently accessed route responses
4. **Monitoring**: Use route statistics to identify bottlenecks

## Testing

The test script (`test-router-api.sh`) includes comprehensive tests for:

- ✓ Basic routes
- ✓ Single and multiple parameter routes
- ✓ Query parameter handling
- ✓ Dynamic route management
- ✓ Route statistics
- ✓ Concurrent requests
- ✓ Edge cases and special characters
- ✓ Performance benchmarks

## Troubleshooting

### Route Not Found (404)

1. Check route definition
2. Verify HTTP method matches
3. Check parameter names
4. Review route order

### Parameter Not Captured

1. Ensure parameter syntax (`:paramName`)
2. Check parameter extraction (`req.params['paramName']`)
3. Verify route pattern matches request

### Dynamic Route Not Working

1. Verify route was added successfully
2. Check route key format (`METHOD:/path`)
3. Ensure middleware order is correct

## References

- [Express.js Routing](https://expressjs.com/en/guide/routing.html)
- [RESTful API Design](https://restfulapi.net/)
- [HTTP Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)

