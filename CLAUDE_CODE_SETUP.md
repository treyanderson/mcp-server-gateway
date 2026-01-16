# MCP Gateway for Claude Code - Setup Guide

This gateway consolidates **25+ MCP servers** into a single configuration entry for Claude Code, making it available across **ALL your projects**.

## 🎯 Why Use This with Claude Code?

### Before: Multiple MCP Configurations ❌
Every time you start a new project, you need to configure MCPs:
```bash
# Project 1
cd ~/project1
# Configure MCP servers manually...

# Project 2
cd ~/project2
# Configure MCP servers manually again...

# Project 3...
# Repeat forever...
```

### After: One Global Gateway ✅
Configure once, use everywhere:
```bash
# One-time setup
cd ~/mcp-server-gateway
./update-claude-code-config.sh

# Now ALL your projects have access to:
# GitHub, Cloudflare, Stripe, Twilio, Brave Search,
# Firecrawl, ElevenLabs, Docker, Puppeteer, and 20+ more!
```

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Run the Setup Script

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
./update-claude-code-config.sh
```

This will:
- Backup your existing `~/.claude.json`
- Add the gateway to your Claude Code global config
- Show you a confirmation

### Step 2: Restart Claude Code

**IMPORTANT:** Completely quit Claude Code (not just close the terminal) and restart it.

### Step 3: Test It

Start Claude Code in any project directory and ask:

```
"What MCP tools do you have available?"
```

You should see tools from all your configured servers!

---

## 🧪 Testing in Different Projects

The beauty of this setup is that it works **everywhere**:

```bash
# Test in project 1
cd ~/my-web-app
claude-code
# Ask: "Search GitHub for React hooks examples"

# Test in project 2
cd ~/another-project
claude-code
# Ask: "Use Cloudflare Workers to create an API"

# Test in project 3
cd ~/yet-another-project
claude-code
# Ask: "Search the web for best practices"

# All projects have access to ALL MCP tools!
```

---

## 📊 What's Available?

Your gateway is pre-configured with 25+ MCP servers:

### ✅ Ready Now (API Keys Already Configured)
- **GitHub** - Repository management, issues, PRs
- **Brave Search** - Web search capabilities
- **Firecrawl** - Web scraping and crawling
- **Context7** - Memory and context management
- **Cloudflare** - Workers, KV, R2, D1, Pages
- **ElevenLabs** - Text-to-speech generation
- **Chrome DevTools** - Browser debugging
- **Filesystem** - File system access
- **Memory** - Persistent memory across sessions
- **Docker** - Container management
- **Puppeteer** - Browser automation
- **Desktop Commander** - Terminal control
- **Sequential Thinking** - Step-by-step reasoning

### ⚠️ Add API Keys to Enable
- **Twilio** - SMS & voice communication
- **Stripe** - Payment processing
- **Neon** - Serverless Postgres
- **Azure** - Cloud services
- **Slack** - Workspace integration
- **PostgreSQL** - Database access
- **Google Drive** - File storage
- **Sentry** - Error tracking

---

## ⚙️ Customization

### Enable/Disable Servers

Edit `config.json`:

```json
{
  "servers": {
    "expensive-server": {
      "command": "npx",
      "args": ["..."],
      "disabled": true  // ← Add this to disable
    }
  }
}
```

### Add API Keys

Edit `.env`:

```bash
# Add your API keys
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
STRIPE_API_KEY=sk_live_...
NEON_API_KEY=your_key
```

Then restart Claude Code.

### Add New Servers

1. Edit `config.json`:
```json
{
  "servers": {
    "my-new-server": {
      "command": "npx",
      "args": ["-y", "my-mcp-server"],
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

2. Add to `.env`:
```bash
MY_API_KEY=your_key_here
```

3. Restart Claude Code - it will automatically discover the new server!

---

## 🎨 Use Cases

### Example 1: Web Development Project
```bash
cd ~/my-web-app
claude-code
```

**Claude Code now has:**
- GitHub integration (manage your repo)
- Web search (research solutions)
- Filesystem access (edit files)
- Puppeteer (test your site)
- Docker (manage containers)

### Example 2: AI/ML Project
```bash
cd ~/ml-project
claude-code
```

**Claude Code now has:**
- Neon Postgres (database for models)
- ElevenLabs (voice synthesis)
- Memory (persist training configs)
- Context7 (manage experiment context)
- Filesystem (access datasets)

### Example 3: E-commerce Project
```bash
cd ~/shop-app
claude-code
```

**Claude Code now has:**
- Stripe (payment processing)
- Twilio (SMS notifications)
- Cloudflare (CDN and API)
- PostgreSQL (product database)
- Sentry (error tracking)

---

## 🔧 Advanced Configuration

### Project-Specific Overrides

Want to disable certain servers for a specific project? Create `.mcp.json` in that project:

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "stdio",
      "command": "node",
      "args": [
        "/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway/dist/index.js",
        "/Users/trey/my-project/custom-config.json"
      ]
    }
  }
}
```

Then create `custom-config.json` with only the servers you want for that project.

### Multiple Configurations

Keep different configs for different scenarios:

```bash
# Default config (all servers)
config.json

# Minimal config (just GitHub and filesystem)
config.minimal.json

# Development config (with debugging tools)
config.dev.json

# Production config (only production-safe servers)
config.prod.json
```

Use them:
```bash
# In a project's .mcp.json
"args": ["..../dist/index.js", "./config.minimal.json"]
```

---

## 🐛 Troubleshooting

### Gateway Not Working

1. **Check if gateway is running:**
```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
npm start
```

Look for:
```
[gateway] Initializing...
[gateway] Connecting to N servers...
[github] Connected - X tools...
```

2. **Check Claude Code config:**
```bash
grep -A 10 '"mcpServers"' ~/.claude.json | grep -A 10 gateway
```

Should show:
```json
"mcp-gateway": {
  "type": "stdio",
  "command": "node",
  "args": ["/path/to/dist/index.js"]
}
```

3. **Rebuild gateway:**
```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
npm run clean
npm run build
```

### Tools Not Showing Up

1. **Restart Claude Code completely**
2. **Check server connections** in gateway logs
3. **Verify API keys** in `.env` file
4. **Disable failing servers** in `config.json`

### Server Connection Failures

If a specific server keeps failing:

1. Check its logs in gateway output
2. Verify API key is correct in `.env`
3. Temporarily disable it:

```json
// config.json
{
  "servers": {
    "problematic-server": {
      "disabled": true
    }
  }
}
```

### Performance Issues

If Claude Code is slow to start:

1. **Disable unused servers** - Edit `config.json` and set `"disabled": true`
2. **Check which servers are slow** - Look at gateway startup logs
3. **Create a minimal config** - Use only the servers you actually need

---

## 📈 Monitoring

### Watch Gateway Logs

In one terminal:
```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
npm start 2>&1 | tee gateway.log
```

In another terminal:
```bash
cd ~/my-project
claude-code
```

You'll see all MCP requests and responses in the gateway terminal.

### Check Connection Status

When gateway starts, it shows:
```
[gateway] Connected to 15/20 servers
[gateway] Total capabilities: 87 tools, 23 resources, 12 prompts
```

This tells you:
- How many servers connected successfully
- Total tools available to Claude Code

---

## 🎓 Best Practices

### 1. Start with Minimal Configuration

Don't enable all 25 servers at once. Start with:
- GitHub
- Filesystem
- Memory
- Brave Search

Then add more as needed.

### 2. Use Project-Specific Configs for Specialized Work

Create custom configs for specialized projects:
- `config.ml.json` - ML projects (only data tools)
- `config.web.json` - Web projects (only web tools)
- `config.backend.json` - Backend projects (DB + API tools)

### 3. Keep API Keys Secure

Never commit `.env` to git:
```bash
# Verify it's in .gitignore
grep .env .gitignore
```

### 4. Monitor Resource Usage

Some MCP servers are resource-heavy. If Claude Code is slow:
```bash
# Check memory usage
ps aux | grep node | grep mcp
```

Disable heavy servers you don't need.

---

## 🚀 Next Steps

1. ✅ **Run** `./update-claude-code-config.sh`
2. ✅ **Restart** Claude Code completely
3. ✅ **Test** in any project directory
4. ⚙️ **Customize** `config.json` to your needs
5. 🔑 **Add** more API keys to `.env` to enable additional servers
6. 📊 **Monitor** gateway logs to see what's being used
7. 🎨 **Create** project-specific configs for specialized workflows

---

## 💡 Tips

- **Use web search** for researching solutions during development
- **Use GitHub tools** to create issues and PRs directly from Claude Code
- **Use filesystem** to let Claude Code read/write files in your project
- **Use memory** to maintain context across sessions
- **Use browser automation** to test your web apps
- **Use ElevenLabs** to generate voice for your apps
- **Use Cloudflare** to deploy serverless functions
- **Use Stripe** to add payments to your apps

---

## 📞 Support

**Gateway Issues:**
Check logs: `npm start` in the gateway directory

**Claude Code Issues:**
Check Claude Code logs: `~/.claude/logs/`

**Configuration Issues:**
Your backup config: `~/.claude.json.backup.[timestamp]`

---

**Status:** ✅ Ready for Production Use

**Compatible with:** Claude Code CLI (all versions)

**Location:** `/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway`

---

*Built specifically for Claude Code development workflows*
