# 🚀 START HERE - MCP Gateway for Claude Code

## What Is This?

A **single configuration** that gives **every Claude Code session** access to **25+ MCP servers** across **all your projects**.

No more configuring MCP servers per-project. Configure once, use everywhere.

---

## Quick Start (30 Seconds)

```bash
# You are here:
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# Step 1: Run setup
./update-claude-code-config.sh

# Step 2: Restart Claude Code completely

# Step 3: Test it
cd ~/any-project
claude-code
# Ask: "What MCP tools do you have available?"
```

**Done!** All 25+ MCP tools are now available in EVERY Claude Code session.

---

## What Tools Do You Get?

### ✅ Already Working (API Keys Configured)

Your `.env` file already has keys for:

- **GitHub** - Manage repos, issues, PRs
- **Brave Search** - Web search
- **Cloudflare** - Workers, KV, R2, Pages
- **ElevenLabs** - Text-to-speech
- **Firecrawl** - Web scraping
- **Context7** - Memory/context
- **Filesystem** - File access to /Users/trey
- **Memory** - Persistent storage
- **Docker** - Container management
- **Puppeteer** - Browser automation
- **Chrome DevTools** - Browser debugging
- **Desktop Commander** - Terminal control
- **Sequential Thinking** - Step-by-step reasoning

### ⚠️ Add Keys to Enable More

Edit `.env` to add:

- **Twilio** (SMS) - `TWILIO_ACCOUNT_SID` + `TWILIO_AUTH_TOKEN`
- **Stripe** (Payments) - `STRIPE_API_KEY`
- **Neon** (Postgres) - `NEON_API_KEY`
- **Azure** (Cloud) - Azure credentials
- **Slack** (Workspace) - `SLACK_BOT_TOKEN`
- **PostgreSQL** - `POSTGRES_CONNECTION_STRING`
- **Google Drive** - Google OAuth credentials
- **Sentry** (Errors) - `SENTRY_AUTH_TOKEN`

---

## Example: Use It Right Now

```bash
# Go to ANY project
cd ~/my-project

# Start Claude Code
claude-code

# Try these:
# "Search GitHub for MCP servers"
# "Search the web for TypeScript tutorials"
# "Use Puppeteer to test localhost:3000"
# "List files in my current directory"
# "What's in my .env file?" (Filesystem)
```

---

## How It Works

**Before:**
```
Project 1 → Configure MCP servers
Project 2 → Configure MCP servers again
Project 3 → Configure MCP servers AGAIN
...
```

**Now:**
```
~/.claude.json → One gateway config
   ↓
Works in ALL projects automatically
   ↓
GitHub, Cloudflare, Stripe, Twilio, Brave, Firecrawl,
ElevenLabs, Docker, Puppeteer, and 20+ more available everywhere!
```

---

## Documentation

### Quick Guides
- **THIS FILE** - Start here! 👈
- **CLAUDE_CODE_QUICKSTART.md** - 30-second setup
- **CLAUDE_CODE_SUMMARY.md** - Complete overview

### Detailed Docs
- **CLAUDE_CODE_SETUP.md** - Full setup guide
- **README.md** - Complete documentation
- **examples/README.md** - Project-specific configs

### Configuration
- **config.json** - Which servers are enabled
- **.env** - Your API keys (already populated!)
- **examples/** - Pre-made configs for different scenarios

---

## Common Tasks

### Customize Which Servers Are Enabled

```bash
# Edit config.json
vim config.json

# Disable a server:
{
  "servers": {
    "unused-server": {
      "disabled": true
    }
  }
}
```

### Add More API Keys

```bash
# Edit .env
vim .env

# Add keys:
STRIPE_API_KEY=sk_live_xxx
TWILIO_ACCOUNT_SID=ACxxx
NEON_API_KEY=xxx
```

Then restart Claude Code.

### Use Different Config for Specific Project

```bash
cd ~/special-project

# Copy example config
cp ~/mcp-server-gateway/examples/config.minimal.json ./

# Create .mcp.json
cat > .mcp.json << 'EOF'
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
EOF
```

### Check Gateway Status

```bash
# Run gateway manually to see logs
npm start

# Look for:
# [gateway] Connected to N/M servers
# [gateway] Total capabilities: X tools, Y resources, Z prompts
```

---

## Troubleshooting

### Gateway Not Working?

1. **Rebuild:**
   ```bash
   npm run build
   ```

2. **Check config:**
   ```bash
   grep -A 10 mcpServers ~/.claude.json | grep -A 10 gateway
   ```

3. **Test manually:**
   ```bash
   npm start
   # Should see server connections
   ```

### Tools Not Showing in Claude Code?

1. **Completely quit and restart Claude Code**
2. Run `npm start` to verify gateway works
3. Check `~/.claude.json` has the gateway config

### A Specific Server Failing?

1. **Check API key in `.env`**
2. **Disable it temporarily:**
   ```bash
   # In config.json
   "problematic-server": {
     "disabled": true
   }
   ```

---

## Real-World Examples

### Web Development

```bash
cd ~/my-web-app
claude-code
```

**Ask Claude:**
- "Use Puppeteer to test the login page"
- "Deploy this to Cloudflare Pages"
- "Search the web for React hooks best practices"

### API Development

```bash
cd ~/api-project
claude-code
```

**Ask Claude:**
- "Create a Cloudflare Worker for this endpoint"
- "Query the Postgres database for user stats"
- "Add Stripe payment processing"

### DevOps

```bash
cd ~/infra-project
claude-code
```

**Ask Claude:**
- "List all Docker containers"
- "Deploy to Azure"
- "Check Sentry for recent errors"

---

## What's Next?

1. ✅ **Run** `./update-claude-code-config.sh`
2. ✅ **Restart** Claude Code
3. ✅ **Test** in any project
4. 🔑 **Add more API keys** to `.env`
5. ⚙️ **Customize** `config.json`
6. 📚 **Read** CLAUDE_CODE_SETUP.md for details
7. 🎨 **Explore** `examples/` for specialized configs

---

## File Structure

```
mcp-server-gateway/
├── START_HERE.md ⭐️ YOU ARE HERE
├── CLAUDE_CODE_QUICKSTART.md    # 30-second guide
├── CLAUDE_CODE_SETUP.md          # Full setup
├── CLAUDE_CODE_SUMMARY.md        # Overview
├── README.md                     # Complete docs
├── config.json                   # Server config
├── .env                          # Your API keys ✅
├── src/                          # Gateway code
├── dist/                         # Built gateway ✅
├── examples/                     # Example configs
│   ├── config.minimal.json
│   ├── config.web-dev.json
│   ├── config.backend.json
│   └── config.ecommerce.json
└── update-claude-code-config.sh  # Setup script
```

---

## Status

✅ **Built and ready**
✅ **Your API keys migrated**
✅ **25+ servers configured**
✅ **Claude Code script ready**
✅ **Documentation complete**

**Just run:**
```bash
./update-claude-code-config.sh
```

---

## Support

**Questions?** Read the docs:
- Quick: CLAUDE_CODE_QUICKSTART.md
- Detailed: CLAUDE_CODE_SETUP.md
- Examples: examples/README.md

**Issues?** Check:
- Gateway logs: `npm start`
- Claude Code config: `~/.claude.json`
- API keys: `.env`

---

**Project Location:**
```
/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
```

**Version:** 1.0.0
**Status:** Production Ready
**Built for:** Claude Code CLI

---

# 🎉 Ready to Go!

```bash
./update-claude-code-config.sh
```

*One gateway. All projects. All tools.*
