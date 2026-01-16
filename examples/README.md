# Example Configurations

This directory contains example configurations for different development scenarios.

## Available Configurations

### config.minimal.json
**Use for:** Quick prototyping, learning
**Includes:**
- Filesystem access
- GitHub integration
- Memory
- Web search (Brave)

**Setup:**
```bash
# Use in a project
cd ~/my-project
mkdir .mcp
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "stdio",
      "command": "node",
      "args": [
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/dist/index.js",
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/examples/config.minimal.json"
      ]
    }
  }
}
EOF
```

### config.web-dev.json
**Use for:** Frontend/fullstack web development
**Includes:**
- All minimal tools
- Puppeteer (browser automation)
- Chrome DevTools
- Cloudflare (Workers, Pages)
- Docker
- Firecrawl (web scraping)

**Use cases:**
- Testing web applications
- Debugging browser issues
- Deploying to Cloudflare
- Scraping competitor sites

### config.backend.json
**Use for:** Backend/API development
**Includes:**
- Filesystem and GitHub
- PostgreSQL access
- Neon serverless Postgres
- Docker
- Cloudflare Workers
- Sentry error tracking

**Use cases:**
- Database-driven applications
- API development
- Microservices
- Error monitoring

### config.ecommerce.json
**Use for:** E-commerce projects
**Includes:**
- Stripe payments
- Twilio SMS
- PostgreSQL
- Cloudflare
- Sentry
- GitHub

**Use cases:**
- Online stores
- Payment processing
- Order notifications
- Customer support

## How to Use

### Option 1: Global Configuration (Recommended)

Use the default `config.json` which includes everything:

```bash
./update-claude-code-config.sh
```

### Option 2: Project-Specific Configuration

Override the global config for a specific project:

1. **Copy example to your project:**
```bash
cd ~/my-project
cp ~/mcp-server-gateway/examples/config.minimal.json ./
```

2. **Create .mcp.json:**
```json
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "stdio",
      "command": "node",
      "args": [
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/dist/index.js",
        "./config.minimal.json"
      ]
    }
  }
}
```

3. **Start Claude Code in that project:**
```bash
claude-code
```

### Option 3: Create Your Own

Copy and customize any example:

```bash
cp config.minimal.json ~/my-custom-config.json
# Edit ~/my-custom-config.json
# Add/remove servers as needed
```

Use it:
```json
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "stdio",
      "command": "node",
      "args": [
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/dist/index.js",
        "/Users/trey/my-custom-config.json"
      ]
    }
  }
}
```

## Tips

### Start Minimal, Add as Needed

Begin with `config.minimal.json` and add servers when you need them:

1. Copy minimal config
2. Edit to add one server at a time
3. Test each addition
4. Keep only what you use

### Use Different Configs for Different Project Types

```bash
~/configs/
  ├── mcp-web.json       # For web projects
  ├── mcp-backend.json   # For backend projects
  ├── mcp-ml.json        # For ML projects
  └── mcp-mobile.json    # For mobile projects
```

Reference in `.mcp.json`:
```json
"args": ["..../dist/index.js", "~/configs/mcp-web.json"]
```

### Combine with .env Files

Store sensitive keys separately:

```bash
# ~/configs/.env.web
CLOUDFLARE_API_TOKEN=xxx
FIRECRAWL_API_KEY=xxx

# ~/configs/.env.backend
POSTGRES_CONNECTION_STRING=xxx
NEON_API_KEY=xxx
```

Load them:
```bash
# In your project
cp ~/configs/.env.web ./.env
```

## Performance Notes

**Server Count vs Speed:**
- 5 servers: ~2s startup
- 10 servers: ~3s startup
- 20 servers: ~5s startup
- 30 servers: ~7s startup

**Recommendation:** Use project-specific configs with 5-10 servers for best performance.

## Creating Custom Configs

Template:
```json
{
  "gateway": {
    "name": "my-custom-gateway",
    "version": "1.0.0"
  },
  "servers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

Find more MCP servers:
- https://github.com/modelcontextprotocol/servers
- https://github.com/punkpeye/awesome-mcp-servers
- https://mcpcat.io

---

**Need help?** Check the main [CLAUDE_CODE_SETUP.md](../CLAUDE_CODE_SETUP.md) guide.
