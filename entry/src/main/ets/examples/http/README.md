# HTTP Server Example

## Overview

This example demonstrates a complete HTTP server implementation with RESTful API, file upload, and static file serving capabilities using the WebServer framework.

## Features

- ✅ Complete RESTful API (CRUD operations)
- ✅ User management with pagination and search
- ✅ File upload and management
- ✅ Static file serving
- ✅ Request logging
- ✅ Error handling
- ✅ CORS support

## Quick Start

### 1. Start the Server

Run the HttpPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8080`

### 2. Access Web Interface

Open your browser and navigate to:
- Homepage: `http://192.168.2.38:8080/`
- Upload page: `http://192.168.2.38:8080/upload.html`

### 3. Test with curl

```bash
# Get user list
curl http://192.168.2.38:8080/api/users

# Create a user
curl -X POST http://192.168.2.38:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"TestUser"}'

# Upload a file
curl -X POST http://192.168.2.38:8080/api/upload \
  -F "uploadFile=@test.txt"
```

### 4. Run Test Script

```bash
chmod +x test-api.sh
./test-api.sh
```

## API Endpoints

### User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | Get all users (with pagination & search) |
| GET | `/api/users/:id` | Get user by ID |
| POST | `/api/users` | Create new user |
| PUT | `/api/users/:id` | Update user |
| DELETE | `/api/users/:id` | Delete user |

### File Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/upload` | Upload file |
| GET | `/api/files` | Get uploaded files list |

### Static Files

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Homepage |
| GET | `/upload.html` | File upload page |

## API Usage Examples

### User Management

#### Get Users with Pagination

```bash
curl "http://IP:8080/api/users?page=1&limit=10"
```

Response:
```json
{
  "users": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3
  }
}
```

#### Search Users

```bash
curl "http://IP:8080/api/users?search=john"
```

#### Get Single User

```bash
curl http://IP:8080/api/users/1
```

Response:
```json
{
  "user": {
    "id": 1,
    "name": "cxy"
  }
}
```

#### Create User

```bash
curl -X POST http://IP:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"NewUser"}'
```

Response:
```json
{
  "message": "User created successfully",
  "user": {
    "id": 3,
    "name": "NewUser"
  }
}
```

#### Update User

```bash
curl -X PUT http://IP:8080/api/users/3 \
  -H "Content-Type: application/json" \
  -d '{"name":"UpdatedName"}'
```

#### Delete User

```bash
curl -X DELETE http://IP:8080/api/users/3
```

### File Management

#### Upload File

```bash
curl -X POST http://IP:8080/api/upload \
  -F "uploadFile=@document.pdf"
```

Response:
```json
{
  "message": "File uploaded successfully",
  "file": {
    "originalName": "document.pdf",
    "savedName": "1640000000000_document.pdf",
    "size": 102400,
    "contentType": "application/pdf",
    "uploadTime": "2024-01-01T00:00:00.000Z",
    "path": "/data/storage/.../1640000000000_document.pdf"
  }
}
```

#### Get File List

```bash
curl http://IP:8080/api/files
```

Response:
```json
{
  "files": [
    {
      "name": "1640000000000_document.pdf",
      "path": "/data/storage/.../1640000000000_document.pdf"
    }
  ],
  "count": 1
}
```

## Code Structure

### Middleware Stack

1. **Logger Middleware**: Logs all requests
2. **CORS Middleware**: Handles cross-origin requests
3. **Body Parser**: Automatically parses request body (JSON, form data, multipart)
4. **Static Files**: Serves static files from configured directory
5. **Error Handler**: Global error handling

### Event Handling

The server monitors various events:
- Server started/stopped
- Request errors
- File operations

## Testing

The test script (`test-api.sh`) includes comprehensive tests for:

- ✓ User CRUD operations
- ✓ Pagination and search
- ✓ File upload
- ✓ File listing
- ✓ Static file serving
- ✓ Error handling

## Error Handling

The server includes global error handling that returns structured error responses:

```json
{
  "error": "Error Type",
  "message": "Detailed error message",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "path": "/api/users",
  "method": "POST"
}
```

## Performance Tips

1. **Pagination**: Always use pagination for large datasets
2. **Search**: Implement efficient search algorithms
3. **File Size**: Limit upload file sizes
4. **Caching**: Use appropriate cache headers for static files
5. **Logging**: Configure appropriate log levels for production

## Security Considerations

1. **Input Validation**: Always validate user input
2. **File Upload**: Validate file types and sizes
3. **CORS**: Configure appropriate CORS policies
4. **Error Messages**: Don't expose sensitive information in errors
5. **Rate Limiting**: Consider implementing rate limiting for production

## References

- [RESTful API Design](https://restfulapi.net/)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [File Upload Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
