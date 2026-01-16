# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mcp-server-gateway** - A gateway/proxy service for Model Context Protocol (MCP) servers, enabling unified access to multiple MCP server implementations.

## Architecture Guidelines

### Core Concepts

This project implements a gateway pattern for MCP (Model Context Protocol) servers. The gateway should:

- **Route requests** to appropriate MCP server implementations
- **Aggregate responses** from multiple MCP servers
- **Handle authentication/authorization** for MCP server access
- **Provide unified API** for clients to interact with multiple MCP servers
- **Support dynamic registration** of new MCP server endpoints

### Technology Stack Decisions

When implementing this project, consider:

- **Node.js/TypeScript** for gateway implementation (standard for MCP ecosystem)
- **HTTP/WebSocket** for client communication
- **JSON-RPC 2.0** protocol (MCP standard)
- **Docker** for containerization of gateway and managed MCP servers
- **Environment-based configuration** for MCP server endpoints

### Key Design Patterns

1. **Gateway Pattern**: Central entry point for all MCP server communications
2. **Service Registry**: Dynamic discovery and registration of MCP servers
3. **Request/Response Transformation**: Protocol adaptation between clients and servers
4. **Circuit Breaker**: Fault tolerance for downstream MCP server failures
5. **Load Balancing**: Distribute requests across multiple instances of same MCP server type

## Development Commands

### Setup and Build

```bash
# Initial setup (installs deps, creates .env, builds)
./setup.sh

# Install dependencies
npm install

# Build TypeScript to JavaScript
npm run build

# Development mode (auto-reload with tsx)
npm run dev

# Type check without building
npm run type-check

# Clean build artifacts
npm run clean
```

### Testing the Gateway

```bash
# Run gateway directly (see logs in terminal)
npm start

# Or run the built version
node dist/index.js

# Test with custom config
node dist/index.js ./config.custom.json
```

### Project Structure

```
src/
  ├── index.ts           # Entry point & CLI
  ├── gateway.ts         # Main gateway server (MCP server interface)
  ├── server-manager.ts  # Manages downstream MCP client connections
  ├── config-loader.ts   # Loads config.json with env var substitution
  └── types.ts           # TypeScript type definitions

config.json              # MCP server definitions
.env                     # API keys and secrets (gitignored)
```

## MCP Gateway Architecture

### How It Works

The gateway acts as a **single MCP server** that internally manages **multiple MCP client connections** to downstream servers.

```
Claude Desktop (MCP Client)
        ↓
   [stdio transport]
        ↓
   MCP Gateway (Server)
        ↓
   Server Manager (Multiple Clients)
        ↓
   [stdio transports to each server]
        ↓
   GitHub, Cloudflare, Stripe, etc. (MCP Servers)
```

### Request Flow

1. **Client request** arrives via stdio (tools/list, tools/call, etc.)
2. **Gateway aggregates** capabilities from all connected servers
3. **Router determines** which server should handle the request
4. **Request forwarded** to appropriate downstream server via its client
5. **Response returned** back through the gateway to the client

### Server Configuration Format

In `config.json`:

```json
{
  "servers": {
    "server-id": {
      "command": "npx",           // Command to spawn server
      "args": ["-y", "package"],  // Args for the command
      "env": {                     // Environment variables
        "API_KEY": "${API_KEY}"   // Supports ${VAR} substitution
      },
      "disabled": false            // Set true to disable
    }
  }
}
```

## Security Considerations

- **Validate all MCP server responses** before forwarding to clients
- **Implement rate limiting** per client and per MCP server
- **Sanitize environment variables** passed to stdio MCP servers
- **Use authentication tokens** for gateway access
- **Log all requests** for audit trail
- **Isolate MCP server processes** (separate containers/sandboxes)

## Testing Strategy

### Unit Tests
- Router logic (request matching to servers)
- Response aggregation
- Protocol transformation
- Authentication middleware

### Integration Tests
- Full request/response cycle with mock MCP servers
- Multiple server coordination
- Failure handling and circuit breaking
- WebSocket connection management

### E2E Tests
- Real MCP server integration (filesystem, github, etc.)
- Client SDK compatibility
- Performance under load

## Configuration Management

### Environment Variables

```bash
# Gateway Configuration
GATEWAY_PORT=3000
GATEWAY_HOST=0.0.0.0

# MCP Server Registry
MCP_SERVERS_CONFIG_PATH=./servers.json

# Security
AUTH_TOKEN_SECRET=<secret>
ALLOWED_ORIGINS=http://localhost:3000

# Logging
LOG_LEVEL=info
```

### MCP Servers Configuration File

Store registered MCP servers in `servers.json`:

```json
{
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    },
    "github": {
      "type": "http",
      "url": "http://localhost:3001/mcp"
    }
  }
}
```

## Common Development Patterns

### Adding a New MCP Server Connector

1. Create connector in `src/servers/<server-name>.ts`
2. Implement `MCPServerConnector` interface
3. Register in `src/registry/index.ts`
4. Add configuration schema
5. Write integration tests

### Implementing Request Routing

- Match requests to server capabilities
- Support wildcard/pattern matching for tool names
- Handle conflicts (multiple servers with same tool)
- Provide fallback mechanisms

### Error Handling

- **Upstream errors**: Return structured error from MCP server
- **Gateway errors**: Return consistent error format
- **Timeout handling**: Configurable per-server timeouts
- **Retry logic**: Exponential backoff for transient failures

## Performance Optimization

- **Connection pooling** for HTTP-based MCP servers
- **Keep-alive** for stdio processes (don't restart per request)
- **Response caching** for idempotent read operations
- **Parallel requests** when querying multiple servers
- **Streaming responses** for large payloads

## Docker Support

```dockerfile
# Dockerfile structure
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
CMD ["node", "dist/index.js"]
```

```yaml
# docker-compose.yml for development
version: '3.8'
services:
  gateway:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./servers.json:/app/servers.json
    environment:
      - NODE_ENV=development
```

## Debugging

### Enable Debug Logging

```bash
DEBUG=mcp:* npm run dev
```

### Inspect MCP Server Communication

- Log all JSON-RPC messages (request/response)
- Track server process lifecycle (start/stop/restart)
- Monitor resource usage per MCP server
- Trace request routing decisions

### Common Issues

1. **MCP server not starting**: Check command path, permissions, dependencies
2. **Timeout errors**: Adjust timeout settings, check server responsiveness
3. **Protocol errors**: Validate JSON-RPC 2.0 compliance
4. **Memory leaks**: Monitor stdio process cleanup, connection pooling

## References

- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Example MCP Servers](https://github.com/modelcontextprotocol/servers)

---

**Last Updated**: 2025-10-27
**Status**: Initial project setup
