# Event Example

## Overview

This example demonstrates the WebServer framework's comprehensive event system. The framework emits various events during server lifecycle and client interactions, allowing you to monitor and respond to server activities in real-time.

## Features

- ✅ Server lifecycle events (start, stop)
- ✅ Client connection events (connect, disconnect)
- ✅ Error event handling
- ✅ Real-time event monitoring
- ✅ Client management
- ✅ Event-driven architecture

## Quick Start

### 1. Start the Server

Run the EventPage in your HarmonyOS app and click "启动服务器" (Start Server).

Default port: `8080`

### 2. Test with curl

```bash
# Get server status
curl http://192.168.2.38:8080/status

# Trigger error event
curl http://192.168.2.38:8080/error
```

### 3. Run Test Script

```bash
chmod +x test-event-api.sh
./test-event-api.sh
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get server status and client count |
| GET | `/status` | Get detailed server status |
| GET | `/error` | Trigger error event (for testing) |
| POST | `/disconnect/:clientId` | Disconnect specific client |

## Event Types

### 1. SERVER_STARTED

Emitted when the server starts successfully.

```typescript
server.on(ServerEventType.SERVER_STARTED, (event) => {
  console.log('Server started:', event.data);
  // event.data contains server address and port
});
```

Event Data:
```json
{
  "address": "192.168.2.38",
  "port": 8080
}
```

### 2. SERVER_STOPPED

Emitted when the server stops.

```typescript
server.on(ServerEventType.SERVER_STOPPED, (event) => {
  console.log('Server stopped');
});
```

### 3. CLIENT_CONNECTED

Emitted when a new client connects.

```typescript
server.on(ServerEventType.CLIENT_CONNECTED, (event) => {
  console.log('Client connected:', event.data);
  // event.data contains client information
});
```

Event Data:
```json
{
  "clientId": 12345,
  "address": "192.168.2.100",
  "port": 54321
}
```

### 4. CLIENT_DISCONNECTED

Emitted when a client disconnects.

```typescript
server.on(ServerEventType.CLIENT_DISCONNECTED, (event) => {
  console.log('Client disconnected:', event.data);
});
```

Event Data:
```json
{
  "clientId": 12345,
  "reason": "normal"
}
```

## Error Events

### Error Types

The framework emits different error types:

- `STARTUP_FAILED`: Server failed to start
- `LISTEN_ERROR`: Port listening failed
- `CONNECTION_ERROR`: Connection error
- `CLIENT_ERROR`: Client-side error
- `SOCKET_ERROR`: Socket error

### Error Handling

```typescript
server.onError((error) => {
  console.error(`Server error [${error.type}]:`, error.error);
  
  switch (error.type) {
    case ServerErrorType.STARTUP_FAILED:
      // Handle startup failure
      break;
    case ServerErrorType.LISTEN_ERROR:
      // Handle listen error
      break;
    case ServerErrorType.CONNECTION_ERROR:
      // Handle connection error
      break;
    default:
      // Handle other errors
  }
});
```

## API Usage

### Get Server Status

```bash
curl http://IP:8080/
```

Response:
```json
{
  "message": "HTTP服务器运行正常",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "clientCount": 3
}
```

### Get Detailed Status

```bash
curl http://IP:8080/status
```

Response:
```json
{
  "status": "running",
  "clientCount": 3,
  "clients": [12345, 12346, 12347],
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Trigger Error Event

```bash
curl http://IP:8080/error
```

This endpoint intentionally throws an error to test error handling.

### Disconnect Client

```bash
curl -X POST http://IP:8080/disconnect/12345
```

Response:
```json
{
  "success": true,
  "message": "客户端 12345 已断开连接"
}
```

## Code Example

```typescript
import { HttpServer, ServerEventType, ServerErrorType } from '@cxy/webserver';

const server = new HttpServer();

// Listen to all server events
Object.values(ServerEventType).forEach(eventType => {
  server.on(eventType, (event) => {
    console.log(`Event [${eventType}]:`, event.data);
  });
});

// Handle errors
server.onError((error) => {
  console.error(`Error [${error.type}]:`, error.error);
  
  switch (error.type) {
    case ServerErrorType.STARTUP_FAILED:
      console.error('Failed to start server');
      break;
    case ServerErrorType.CONNECTION_ERROR:
      console.error('Connection error occurred');
      break;
  }
});

// Setup routes
server.get('/status', (req, res) => {
  res.json({
    status: 'running',
    clientCount: server.getClientCount(),
    clients: server.getClients().map(c => c.clientId)
  });
});

await server.startServer(8080);
```

## Advanced Usage

### Custom Event Handlers

```typescript
// Track connection statistics
let totalConnections = 0;
let activeConnections = 0;

server.on(ServerEventType.CLIENT_CONNECTED, (event) => {
  totalConnections++;
  activeConnections++;
  console.log(`Total: ${totalConnections}, Active: ${activeConnections}`);
});

server.on(ServerEventType.CLIENT_DISCONNECTED, (event) => {
  activeConnections--;
  console.log(`Active connections: ${activeConnections}`);
});
```

### Error Recovery

```typescript
server.onError((error) => {
  if (error.type === ServerErrorType.LISTEN_ERROR) {
    // Try alternative port
    console.log('Port busy, trying alternative port...');
    server.startServer(8080);
  }
});
```

### Client Management

```typescript
// Get all connected clients
const clients = server.getClients();
console.log('Connected clients:', clients);

// Get client count
const count = server.getClientCount();
console.log('Client count:', count);

// Disconnect specific client
await server.disconnectClient(clientId);
```

## Testing

The test script (`test-event-api.sh`) includes comprehensive tests for:

- ✓ Server status queries
- ✓ Error event triggering
- ✓ Client connection events
- ✓ Client disconnection events
- ✓ Stress testing (multiple concurrent connections)
- ✓ Error handling robustness
- ✓ Long connection testing
- ✓ Invalid client ID handling

## Monitoring

### Real-time Monitoring

Monitor server events in real-time by watching the console output:

```bash
# In one terminal, start the server
# In another terminal, run:
watch -n 1 'curl -s http://IP:8080/status | jq .'
```

### Event Logging

All events are automatically logged to the console with timestamps and event data.

## Performance Tips

1. **Event Handlers**: Keep event handlers lightweight
2. **Error Handling**: Always implement error handlers
3. **Client Tracking**: Use events to track client statistics
4. **Resource Cleanup**: Handle disconnection events for cleanup

## Troubleshooting

### Events Not Firing

1. Check event listener registration
2. Verify server is running
3. Check console for error messages

### High Memory Usage

1. Remove unused event listeners
2. Implement proper cleanup in disconnect handlers
3. Monitor client count

### Connection Issues

1. Check firewall settings
2. Verify port availability
3. Review error events

## Use Cases

### 1. Connection Monitoring

Track and log all client connections:

```typescript
server.on(ServerEventType.CLIENT_CONNECTED, (event) => {
  logToDatabase({
    type: 'connection',
    clientId: event.data.clientId,
    timestamp: new Date()
  });
});
```

### 2. Load Balancing

Monitor client count for load balancing decisions:

```typescript
server.on(ServerEventType.CLIENT_CONNECTED, (event) => {
  if (server.getClientCount() > MAX_CLIENTS) {
    redirectToAlternativeServer(event.data.clientId);
  }
});
```

### 3. Error Alerting

Send alerts when errors occur:

```typescript
server.onError((error) => {
  if (error.type === ServerErrorType.STARTUP_FAILED) {
    sendAlert('Server failed to start!');
  }
});
```

## References

- [Event-Driven Architecture](https://en.wikipedia.org/wiki/Event-driven_architecture)
- [Node.js EventEmitter](https://nodejs.org/api/events.html)
- [WebSocket Events](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket#events)

