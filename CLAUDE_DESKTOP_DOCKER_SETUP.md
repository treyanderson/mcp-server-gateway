# Claude Desktop - Docker Gateway Setup

## ✅ Configuration Complete!

Your Claude Desktop is now configured to use the **MCP Gateway Docker container** which aggregates 12 MCP servers into a single endpoint.

---

## 🎯 What Was Added

**Location:** `~/Library/Application Support/Claude/claude_desktop_config.json`

**New Server:** `mcp-gateway-docker`

```json
{
  "mcpServers": {
    "mcp-gateway-docker": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--env-file",
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/.env",
        "-v",
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/config.json:/app/config.json:ro",
        "mcp-gateway:latest"
      ]
    }
  }
}
```

---

## 🚀 Available Through Docker Gateway

When you restart Claude Desktop, you'll have access to **226 tools** from:

| Server | Tools | What It Does |
|--------|-------|--------------|
| **Cloudflare** | 89 | Workers, KV, R2, D1, DNS, Analytics, Queues |
| **Chrome DevTools** | 27 | Browser automation, screenshots, debugging |
| **GitHub** | 26 | Repos, PRs, issues, commits, branches |
| **Desktop Commander** | 25 | Desktop automation, file operations |
| **ElevenLabs** | 24 | Text-to-speech, voice cloning, AI agents |
| **Filesystem** | 14 | File read/write, directory operations |
| **Memory** | 9 | Knowledge graph, entity management |
| **Firecrawl** | 6 | Web scraping, crawling, extraction |
| **Brave Search** | 2 | Web search, local search |
| **Context7** | 2 | Memory & context management |
| **Sequential Thinking** | 1 | Chain-of-thought reasoning |
| **Docker** | 1 | Docker container operations |

---

## 🔄 How to Activate

### Step 1: Ensure Docker Container is Running

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
docker-compose up -d
```

### Step 2: Restart Claude Desktop

- Quit Claude Desktop completely (Cmd+Q)
- Reopen Claude Desktop
- The gateway will connect automatically

### Step 3: Verify Connection

In Claude Desktop, you should see:
- **MCP indicator** showing connected servers
- All 226 tools available in the tools menu

---

## 🔍 Troubleshooting

### Gateway Not Connecting

**Check if container is running:**
```bash
docker ps | grep mcp-gateway
```

**Check container logs:**
```bash
docker-compose logs -f
```

**Restart container:**
```bash
docker-compose restart
```

### Claude Desktop Not Seeing Gateway

**Verify config syntax:**
```bash
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .
```

**Check Claude Desktop logs:**
```bash
tail -f ~/Library/Logs/Claude/mcp*.log
```

**Full restart:**
1. Stop container: `docker-compose down`
2. Quit Claude Desktop
3. Start container: `docker-compose up -d`
4. Reopen Claude Desktop

---

## 🎛️ Managing the Gateway

### Start Gateway
```bash
docker-compose up -d
```

### Stop Gateway
```bash
docker-compose down
```

### Restart Gateway
```bash
docker-compose restart
```

### View Logs
```bash
docker-compose logs -f
```

### Update Gateway
```bash
# Pull latest changes
git pull

# Rebuild Docker image
docker-compose build

# Restart with new image
docker-compose up -d
```

---

## 🔐 Environment Variables

All API keys are stored in `.env` and automatically loaded:

```bash
# View current keys (redacted)
docker exec mcp-gateway printenv | grep -E "API_KEY|TOKEN" | sed 's/=.*/=***/'

# Update a key
nano .env

# Restart to apply
docker-compose restart
```

---

## ⚡ Performance Tips

### Keep Container Running

The container starts instantly when Claude Desktop needs it, but you can keep it running:

```bash
# Add to docker-compose.yml
restart: unless-stopped
```

### Resource Limits

Already configured in `docker-compose.yml`:
- CPU: 2 cores max
- Memory: 2GB max

### Monitor Resources

```bash
docker stats mcp-gateway
```

---

## 🆚 Docker Gateway vs Individual Servers

### **Using Docker Gateway (Recommended)**

**Pros:**
- ✅ All 226 tools through single connection
- ✅ Consistent environment (containerized)
- ✅ Easy updates (rebuild image)
- ✅ Centralized API key management
- ✅ Better resource management

**Cons:**
- ⚠️ Requires Docker Desktop running
- ⚠️ Slightly slower startup (container boot)

### **Using Individual Servers**

**Pros:**
- ✅ No Docker dependency
- ✅ Faster connection per server

**Cons:**
- ❌ 12 separate connections to manage
- ❌ Individual API key configuration
- ❌ More complex troubleshooting
- ❌ Higher memory usage (12 processes)

---

## 🧪 Testing Individual Tools

### Test from Command Line

```bash
# Send test request via stdio
echo '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' | \
  docker run -i --rm \
  --env-file /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/.env \
  -v /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/config.json:/app/config.json:ro \
  mcp-gateway:latest
```

### Test Specific Server

```bash
# Check which servers are connected
docker-compose logs | grep "Connected -"
```

---

## 📊 Monitoring

### Connection Status

```bash
# See which servers connected successfully
docker-compose logs 2>&1 | grep -E "Connected|Failed" | sort | uniq
```

### Tool Count

```bash
# Total tools available
docker-compose logs 2>&1 | grep "Connected -" | \
  awk '{sum+=$4} END {print "Total tools:", sum}'
```

### Server Health

```bash
# Check for errors
docker-compose logs 2>&1 | grep -i error | tail -20
```

---

## 🔄 Updating API Keys

When you need to update an API key:

1. **Edit `.env` file:**
   ```bash
   nano /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/.env
   ```

2. **Restart container:**
   ```bash
   docker-compose restart
   ```

3. **Verify in Claude Desktop:**
   - Quit and reopen Claude Desktop
   - Tools should now work with new key

---

## 🎓 Next Steps

1. **Test the gateway** in Claude Desktop
2. **Explore Cloudflare tools** (89 available!)
3. **Try Chrome DevTools** for browser automation
4. **Use Memory tools** to build knowledge graphs
5. **Experiment with ElevenLabs** for voice generation

---

## 🆘 Need Help?

- **Docker issues:** Check `docker-compose logs`
- **Claude Desktop issues:** Check `~/Library/Logs/Claude/mcp*.log`
- **API key issues:** Verify in `.env` file
- **Connection issues:** Restart both container and Claude Desktop

---

**Last Updated:** 2025-10-27
**Gateway Version:** 1.0.0
**Docker Image:** mcp-gateway:latest
