# Quick Start Guide

## 1. Add Gateway to Claude Desktop

Edit your Claude Desktop config file:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

Replace your existing MCP servers with just the gateway:

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "command": "node",
      "args": [
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/dist/index.js"
      ]
    }
  }
}
```

## 2. Restart Claude Desktop

**IMPORTANT:** Completely quit Claude Desktop (not just close the window) and restart it.

## 3. Test the Gateway

In Claude Desktop, try asking:

- "What tools do you have available?" - Should show all aggregated tools
- "Search GitHub for MCP servers" - Tests GitHub integration
- "Search the web for TypeScript tutorials" - Tests Brave Search
- "Read the file /Users/trey/Desktop/test.txt" - Tests filesystem

## 4. Customize Your Configuration

### Enable/Disable Servers

Edit `config.json` and add `"disabled": true` to any server you don't need:

```json
{
  "servers": {
    "expensive-server": {
      "command": "npx",
      "args": [...],
      "disabled": true
    }
  }
}
```

### Add API Keys

Edit `.env` and add your API keys for the services you want to use:

```bash
# Required for these servers to work:
GITHUB_PERSONAL_ACCESS_TOKEN=your_token
BRAVE_API_KEY=your_key
CLOUDFLARE_API_TOKEN=your_token
STRIPE_API_KEY=your_key
# etc...
```

### Add New Servers

1. Add to `config.json`:
```json
{
  "servers": {
    "my-new-server": {
      "command": "npx",
      "args": ["-y", "my-server-package"],
      "env": {
        "MY_API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

2. Add to `.env`:
```bash
MY_API_KEY=your_key_here
```

3. Restart gateway - it will automatically discover the new server's tools!

## 5. Monitoring

Gateway logs are sent to stderr. To see them:

```bash
# Terminal 1: Watch logs
tail -f ~/Library/Logs/Claude/mcp*.log

# Or run gateway directly to see logs
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
npm start
```

## 6. Troubleshooting

### Gateway not starting

```bash
# Check if gateway can run
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
npm start

# Should see:
# [gateway] Initializing...
# [gateway] Connecting to N servers...
```

### Tools not showing up

1. Check gateway logs for connection errors
2. Verify API keys in `.env`
3. Try disabling problematic servers in `config.json`

### Server keeps failing

Add to `config.json`:
```json
{
  "servers": {
    "problematic-server": {
      "disabled": true
    }
  }
}
```

## Current Configuration

You have these servers configured with API keys already set:

- ✅ **filesystem** - File system access to /Users/trey
- ✅ **github** - GitHub integration (API key configured)
- ✅ **brave-search** - Web search (API key configured)
- ✅ **context7** - Memory/context (API key configured)
- ✅ **firecrawl** - Web scraping (API key configured)
- ✅ **cloudflare** - Cloudflare API (account ID configured)
- ✅ **elevenlabs** - Text-to-speech (API key configured)
- ✅ **chrome-devtools** - Chrome integration
- ✅ **memory** - Persistent memory
- ✅ **sequential-thinking** - Reasoning
- ✅ **puppeteer** - Browser automation
- ✅ **docker** - Docker management
- ✅ **desktop-commander** - Terminal control

These servers need API keys (currently disabled):
- ⚠️ **twilio** - Needs TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN
- ⚠️ **stripe** - Needs STRIPE_API_KEY
- ⚠️ **neon** - Needs NEON_API_KEY
- ⚠️ **azure** - Needs Azure credentials
- ⚠️ **slack** - Needs SLACK_BOT_TOKEN
- ⚠️ **postgres** - Needs POSTGRES_CONNECTION_STRING

## Next Steps

1. **Test the gateway** - Try the commands above in Claude Desktop
2. **Add missing API keys** - Enable more servers by adding keys to `.env`
3. **Customize config** - Disable servers you don't need
4. **Monitor performance** - Watch for slow or failing servers
5. **Add more servers** - Expand your capabilities

---

For full documentation, see [README.md](README.md)
