# MCP Server Gateway for Claude Code

A unified gateway that aggregates 25+ [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers into a single endpoint for **Claude Code**. Configure once globally, use in ALL your development projects.

## 🎯 Why Use This Gateway with Claude Code?

**Before (without gateway):**
Every project needs individual MCP configuration. Tedious and repetitive.

**After (with gateway):**
```bash
# One-time global setup
./update-claude-code-config.sh

# Now EVERY Claude Code session has access to:
# GitHub, Cloudflare, Stripe, Twilio, Brave Search,
# Firecrawl, ElevenLabs, Docker, Puppeteer, and 20+ more!

# Works in ANY project directory:
cd ~/my-web-app && claude-code        # Has all tools
cd ~/api-project && claude-code       # Has all tools
cd ~/ml-experiment && claude-code     # Has all tools
```

All your MCP servers configured once, available everywhere!

## 🚀 Quick Start for Claude Code

### Prerequisites

- Node.js 18+
- Claude Code CLI installed
- npm or yarn

### Setup (3 Steps)

1. **Navigate to the gateway directory:**
   ```bash
   cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
   ```

2. **Run the Claude Code configuration script:**
   ```bash
   ./update-claude-code-config.sh
   ```

   This will:
   - Backup your existing `~/.claude.json`
   - Add the gateway to your Claude Code global configuration
   - Show you a confirmation message

3. **Restart Claude Code:**

   Completely quit Claude Code (not just close the terminal) and restart it.

### Test It

Start Claude Code in ANY project:

```bash
cd ~/any-project-directory
claude-code
```

Ask Claude:
```
"What MCP tools do you have available?"
```

You should see tools from GitHub, Brave Search, Cloudflare, Filesystem, and many more!

### What's Included

The gateway comes pre-configured with **25+ MCP servers** including:

**Development Tools:**
- GitHub, Filesystem, Docker, Desktop Commander

**Web & Search:**
- Brave Search, Firecrawl, Puppeteer, Chrome DevTools

**Cloud Services:**
- Cloudflare, Azure, Neon Postgres

**AI & Communication:**
- ElevenLabs, Twilio, Slack

**Business APIs:**
- Stripe, Sentry, Google Drive

**Utilities:**
- Memory, Sequential Thinking, Context7, Time, Fetch

**And more!**

See [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md) for complete list and setup details.

## 📝 Configuration

### config.json Structure

```json
{
  "gateway": {
    "name": "mcp-gateway",
    "version": "1.0.0"
  },
  "servers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {
        "API_KEY": "${API_KEY}"
      },
      "disabled": false
    }
  }
}
```

### Environment Variable Substitution

The gateway supports `${VAR_NAME}` syntax in `config.json`. Variables are loaded from `.env` file:

```json
{
  "servers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

### Disabling Servers

To disable a server without removing it from config:

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

## 🔌 Included MCP Servers

The gateway comes pre-configured with 25+ MCP servers:

### Development & Productivity
- **filesystem** - File system access
- **github** - GitHub integration (issues, PRs, repos)
- **desktop-commander** - Terminal control and file system operations
- **memory** - Persistent memory across sessions
- **sequential-thinking** - Step-by-step reasoning

### Cloud & Infrastructure
- **cloudflare** - Cloudflare API (Workers, KV, R2, etc.)
- **azure** - Azure cloud services
- **docker** - Docker container management
- **neon** - Neon serverless Postgres
- **postgres** - PostgreSQL database access
- **sqlite** - SQLite database access

### Communication & APIs
- **twilio** - SMS and voice communication
- **slack** - Slack workspace integration
- **stripe** - Payment processing
- **resend** - Email delivery (if available)

### AI & Automation
- **elevenlabs** - Text-to-speech
- **puppeteer** - Browser automation
- **brave-search** - Web search
- **firecrawl** - Web scraping

### Developer Tools
- **chrome-devtools** - Chrome DevTools integration
- **context7** - Context management
- **sentry** - Error tracking
- **google-drive** - Google Drive integration

### Utilities
- **time** - Time and timezone operations
- **fetch** - HTTP request capabilities

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

1. **Build and start:**
   ```bash
   docker-compose up -d
   ```

2. **View logs:**
   ```bash
   docker-compose logs -f mcp-gateway
   ```

3. **Stop:**
   ```bash
   docker-compose down
   ```

### Using Dockerfile

```bash
# Build image
docker build -t mcp-gateway .

# Run container
docker run -it --rm \
  --env-file .env \
  -v $(pwd)/config.json:/app/config.json:ro \
  mcp-gateway
```

## 🎨 Use Cases with Claude Code

### Web Development

```bash
cd ~/my-web-app
claude-code
```

**Claude now has:**
- GitHub integration (manage repo)
- Puppeteer (test your site)
- Chrome DevTools (debug)
- Cloudflare (deploy Workers)
- Brave Search (research)

**Ask:** "Use Puppeteer to test the login flow on localhost:3000"

### Backend Development

```bash
cd ~/api-project
claude-code
```

**Claude now has:**
- Postgres/Neon (database access)
- Docker (container management)
- Cloudflare Workers (deploy APIs)
- Sentry (error tracking)
- GitHub (version control)

**Ask:** "Query the users table and create an API endpoint"

### E-commerce Project

```bash
cd ~/shop-app
claude-code
```

**Claude now has:**
- Stripe (payments)
- Twilio (SMS notifications)
- PostgreSQL (product database)
- Cloudflare (CDN)
- GitHub (version control)

**Ask:** "Create a payment flow using Stripe"

## 📊 Monitoring & Debugging

### Enable Debug Logging

The gateway logs to stderr. To see detailed logs:

```bash
npm start 2>&1 | tee gateway.log
```

### Common Log Messages

- `[gateway] Connecting to N servers...` - Starting server connections
- `[server-id] Connected - X tools, Y resources, Z prompts` - Server connected successfully
- `[gateway] Tool call: tool-name` - Incoming tool call
- `[gateway] Routing to server: server-id` - Request routed to specific server

### Checking Server Status

When the gateway starts, it logs the number of successfully connected servers:

```
[gateway] Connected to 15/20 servers
[gateway] Total capabilities: 87 tools, 23 resources, 12 prompts
```

If some servers fail to connect, check:
1. API keys in `.env` file
2. Server package is installed (`npx` handles this automatically)
3. Network connectivity for cloud services

## 🛠️ Development

### Project Structure

```
mcp-server-gateway/
├── src/
│   ├── index.ts           # Entry point
│   ├── gateway.ts         # Main gateway server
│   ├── server-manager.ts  # Manages downstream servers
│   ├── config-loader.ts   # Configuration loader
│   └── types.ts           # TypeScript types
├── config.json            # Server configuration
├── .env.example           # Environment template
├── package.json
├── tsconfig.json
├── Dockerfile
└── docker-compose.yml
```

### Development Commands

```bash
# Run in development mode with auto-reload
npm run dev

# Type check without building
npm run type-check

# Build for production
npm run build

# Clean build artifacts
npm run clean
```

### Adding a New MCP Server

1. Add server configuration to `config.json`:
   ```json
   {
     "servers": {
       "new-server": {
         "command": "npx",
         "args": ["-y", "new-server-package"],
         "env": {
           "NEW_SERVER_API_KEY": "${NEW_SERVER_API_KEY}"
         }
       }
     }
   }
   ```

2. Add environment variables to `.env`:
   ```bash
   NEW_SERVER_API_KEY=your_key_here
   ```

3. Restart the gateway - it will automatically discover the new server's capabilities!

## 🔐 Security Considerations

### Environment Variables

- Never commit `.env` file to version control
- Use `.env.example` as a template
- Store sensitive keys in a secure secret manager in production

### API Key Isolation

Each MCP server runs in its own process with only the environment variables it needs. The gateway doesn't have direct access to API keys - they're passed only to the relevant server process.

### Network Access

Consider restricting network access for the gateway container:
- Only allow outbound connections to required services
- Use Docker networks for isolation
- Implement rate limiting if exposing publicly

## 🐛 Troubleshooting

### Server Won't Start

**Error: `Cannot find module '@modelcontextprotocol/sdk'`**
```bash
# Solution: Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

**Error: `Failed to connect to [server-name]`**
- Check API key is set in `.env`
- Verify server package exists: `npm view package-name`
- Check server logs for specific errors

### Tool Calls Not Working

1. **Check server is connected:**
   Look for connection log: `[server-id] Connected - X tools...`

2. **Verify tool exists:**
   The gateway logs available tools on startup

3. **Check tool name:**
   Tool names must match exactly (case-sensitive)

### High Memory Usage

If the gateway consumes too much memory:

1. **Disable unused servers** in `config.json`:
   ```json
   { "disabled": true }
   ```

2. **Limit concurrent servers:**
   Start fewer servers at once

3. **Check for memory leaks:**
   Monitor individual server processes

### Claude Desktop Not Seeing Tools

1. **Completely quit Claude Desktop** (don't just close window)
2. **Verify config path** in `claude_desktop_config.json`
3. **Check gateway is running:** `ps aux | grep mcp-server-gateway`
4. **Look for errors** in Claude Desktop logs:
   - macOS: `~/Library/Logs/Claude/`
   - Windows: `%APPDATA%\Claude\logs\`
   - Linux: `~/.config/Claude/logs/`

## 📚 Resources

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
- [Claude Desktop Documentation](https://claude.ai/docs)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Anthropic for the Model Context Protocol
- All the MCP server developers
- The open-source community

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/mcp-server-gateway/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/mcp-server-gateway/discussions)

---

**Built with ❤️ for the MCP community**
