# Docker Setup Guide for MCP Gateway

This guide explains how to run the MCP Gateway in Docker Desktop.

---

## 🐳 Prerequisites

1. **Docker Desktop** installed and running
2. **API keys configured** in `.env` file

---

## 🚀 Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and start the gateway
docker-compose up --build

# Run in detached mode (background)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the gateway
docker-compose down
```

### Option 2: Using the Run Script

```bash
# Build and run interactively
./docker-run.sh
```

### Option 3: Manual Docker Commands

```bash
# Build the image
docker build -t mcp-gateway:latest .

# Run the container
docker run -it --rm \
  -v "$(pwd)/.env:/app/.env:ro" \
  -v "$(pwd)config.json:/app/config.json:ro" \
  mcp-gateway:latest
```

---

## 🔧 Configuration for Claude Desktop

To use the Dockerized MCP Gateway with Claude Desktop, update your Claude Desktop config:

**Location:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v",
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/.env:/app/.env:ro",
        "-v",
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/config.json:/app/config.json:ro",
        "mcp-gateway:latest"
      ]
    }
  }
}
```

**Note:** Replace the full paths with your actual project path.

---

## 📦 Building the Image

The Dockerfile uses a multi-stage build:

1. **Builder stage**: Compiles TypeScript
2. **Production stage**: Minimal runtime with only production dependencies

```bash
# Build
docker build -t mcp-gateway:latest .

# Check image size
docker images | grep mcp-gateway

# Rebuild without cache
docker build --no-cache -t mcp-gateway:latest .
```

---

## 🔍 Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs mcp-gateway
```

**Run in interactive mode for debugging:**
```bash
docker run -it --rm \
  -v "$(pwd)/.env:/app/.env:ro" \
  -v "$(pwd)/config.json:/app/config.json:ro" \
  mcp-gateway:latest
```

### API Keys Not Loading

**Verify .env file is mounted:**
```bash
docker run -it --rm \
  -v "$(pwd)/.env:/app/.env:ro" \
  mcp-gateway:latest \
  cat /app/.env
```

**Check permissions:**
```bash
ls -la .env
# Should be readable
```

### MCP Server Connection Failures

**Check which servers are failing:**
```bash
docker logs mcp-gateway 2>&1 | grep -i "error\|fail"
```

**Test individual server:**
```bash
# Example: Test if cloudflare tools work
docker exec -it mcp-gateway npx -y @cloudflare/mcp-server-cloudflare --version
```

### ElevenLabs (Python/uvx) Issues

**Verify Python and uvx are installed:**
```bash
docker run -it --rm mcp-gateway:latest which python3
docker run -it --rm mcp-gateway:latest which uvx
```

**Rebuild if needed:**
```bash
docker-compose build --no-cache
```

---

## 🔄 Updating the Gateway

When you make changes to the code:

```bash
# Rebuild and restart
docker-compose up --build

# Or manually
docker build -t mcp-gateway:latest .
docker-compose restart
```

---

## 🗂️ Project Structure in Container

```
/app/
├── dist/              # Compiled JavaScript
├── config.json        # MCP server configuration
├── .env              # API keys (mounted volume)
├── node_modules/     # Dependencies
└── package.json
```

---

## 🔐 Security Best Practices

1. **Never commit `.env` to Git** (already in `.gitignore`)
2. **Mount `.env` as read-only** (`:ro` flag)
3. **Use Docker secrets** for production:
   ```bash
   docker secret create mcp_env .env
   ```
4. **Scan image for vulnerabilities:**
   ```bash
   docker scan mcp-gateway:latest
   ```

---

## 📊 Resource Management

### Set Resource Limits

Already configured in `docker-compose.yml`:
- CPU: 2 cores max, 0.5 core reserved
- Memory: 2GB max, 512MB reserved

### Monitor Resource Usage

```bash
# Real-time stats
docker stats mcp-gateway

# Check container health
docker ps -a | grep mcp-gateway
```

---

## 🧪 Testing the Container

### Test stdio communication:
```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{},"id":1}' | \
  docker run -i --rm \
  -v "$(pwd)/.env:/app/.env:ro" \
  -v "$(pwd)/config.json:/app/config.json:ro" \
  mcp-gateway:latest
```

### Verify all servers load:
```bash
docker logs mcp-gateway 2>&1 | grep -i "connected\|initialized"
```

---

## 🌐 Alternative: HTTP/WebSocket Transport

If you want to expose the gateway via HTTP instead of stdio:

**1. Modify the gateway code to add HTTP server**

**2. Update Dockerfile to expose port:**
```dockerfile
EXPOSE 3000
```

**3. Update docker-compose.yml:**
```yaml
ports:
  - "3000:3000"
```

**4. Update Claude Desktop config:**
```json
{
  "mcpServers": {
    "mcp-gateway": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

---

## 📝 Docker Commands Reference

```bash
# Build
docker build -t mcp-gateway:latest .

# Run interactive
docker run -it --rm mcp-gateway:latest

# Run detached
docker run -d --name mcp-gateway mcp-gateway:latest

# View logs
docker logs -f mcp-gateway

# Stop
docker stop mcp-gateway

# Remove
docker rm mcp-gateway

# Clean up
docker system prune -a

# Remove all containers and images
docker-compose down --rmi all
```

---

## 🚀 Production Deployment

For production, consider:

1. **Use Docker Hub or private registry:**
   ```bash
   docker tag mcp-gateway:latest yourusername/mcp-gateway:latest
   docker push yourusername/mcp-gateway:latest
   ```

2. **Use environment-specific configs:**
   ```bash
   docker run -it --rm \
     --env-file .env.production \
     mcp-gateway:latest
   ```

3. **Set up health checks:**
   ```yaml
   healthcheck:
     test: ["CMD", "node", "-e", "process.exit(0)"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

4. **Use orchestration (Kubernetes, Docker Swarm)** for scaling

---

**Last Updated:** 2025-10-27
