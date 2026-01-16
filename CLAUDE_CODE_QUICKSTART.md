# MCP Gateway for Claude Code - Quickstart

## One Gateway, All Your Projects

Configure once, use everywhere. This gateway gives **every Claude Code session** access to 25+ MCP servers.

---

## Setup (30 seconds)

```bash
# 1. Navigate to gateway
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# 2. Run setup script
./update-claude-code-config.sh

# 3. Restart Claude Code completely
```

**Done!** Now use Claude Code in ANY project with ALL MCP tools available.

---

## Test It

```bash
# Start Claude Code in ANY directory
cd ~/any-project
claude-code
```

**Ask Claude:**
```
"What MCP tools do you have available?"
```

You should see tools from GitHub, Brave Search, Filesystem, Memory, and more!

---

## What You Get

### ✅ Ready Now (Keys Already Configured)
- **GitHub** - Issues, PRs, repos
- **Brave Search** - Web search
- **Firecrawl** - Web scraping
- **Context7** - Memory management
- **Cloudflare** - Workers, KV, R2
- **ElevenLabs** - Text-to-speech
- **Filesystem** - File access
- **Docker** - Containers
- **Puppeteer** - Browser automation

### ⚠️ Add Keys to Enable
Edit `.env` in the gateway directory:

```bash
# Twilio (SMS)
TWILIO_ACCOUNT_SID=xxx
TWILIO_AUTH_TOKEN=xxx

# Stripe (Payments)
STRIPE_API_KEY=sk_xxx

# Neon (Postgres)
NEON_API_KEY=xxx

# And more...
```

---

## Example Usage

### Web Development
```bash
cd ~/my-web-app
claude-code
```
**Ask:** "Use Puppeteer to test my login page"

### API Development
```bash
cd ~/api-project
claude-code
```
**Ask:** "Create a Cloudflare Worker for this endpoint"

### Database Work
```bash
cd ~/db-project
claude-code
```
**Ask:** "Query my Postgres database for user stats"

---

## Customize

### Disable Unused Servers
Edit `config.json`:
```json
{
  "servers": {
    "unused-server": {
      "disabled": true
    }
  }
}
```

### Project-Specific Config
See [examples/](examples/) directory for:
- `config.minimal.json` - Minimal setup
- `config.web-dev.json` - Web development
- `config.backend.json` - Backend/API
- `config.ecommerce.json` - E-commerce

---

## Troubleshooting

### Tools not showing?
1. Restart Claude Code completely
2. Check: `npm start` in gateway directory
3. Verify `~/.claude.json` has gateway config

### Slow startup?
1. Disable unused servers in `config.json`
2. Use project-specific minimal config

---

## Full Documentation

- **[CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md)** - Complete setup guide
- **[README.md](README.md)** - Full documentation
- **[examples/](examples/)** - Example configurations
- **[config.json](config.json)** - Server configuration

---

**Ready to go?** Run the setup script and start coding!

```bash
./update-claude-code-config.sh
```
