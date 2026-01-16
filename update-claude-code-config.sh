#!/bin/bash
# Update Claude Code global configuration to use MCP Gateway

set -e

GATEWAY_PATH="$(cd "$(dirname "$0")" && pwd)/dist/index.js"
CONFIG_PATH="$HOME/.claude.json"

echo "🔧 MCP Gateway Configuration for Claude Code"
echo "=============================================="
echo ""

# Check if gateway is built
if [ ! -f "$GATEWAY_PATH" ]; then
    echo "❌ Gateway not built. Run 'npm run build' first."
    exit 1
fi

echo "✅ Gateway found at: $GATEWAY_PATH"
echo ""

# Backup existing config
if [ ! -f "$CONFIG_PATH" ]; then
    echo "⚠️  No Claude Code config found at $CONFIG_PATH"
    echo "Creating new configuration..."
    echo '{}' > "$CONFIG_PATH"
fi

BACKUP_PATH="${CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
echo "📦 Backing up existing config to:"
echo "   $BACKUP_PATH"
cp "$CONFIG_PATH" "$BACKUP_PATH"
echo ""

# Use jq to update the config if available, otherwise use a simple approach
if command -v jq &> /dev/null; then
    echo "📝 Adding gateway to Claude Code config (using jq)..."

    # Create the gateway config
    GATEWAY_CONFIG=$(cat <<EOF
{
  "mcpServers": {
    "mcp-gateway": {
      "type": "stdio",
      "command": "node",
      "args": ["$GATEWAY_PATH"]
    }
  }
}
EOF
)

    # Merge with existing config
    jq -s '.[0] * .[1]' "$CONFIG_PATH" <(echo "$GATEWAY_CONFIG") > "${CONFIG_PATH}.tmp"
    mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"

    echo "✅ Configuration updated!"
else
    echo "⚠️  jq not found. Please manually add this to your ~/.claude.json:"
    echo ""
    echo "  \"mcpServers\": {"
    echo "    \"mcp-gateway\": {"
    echo "      \"type\": \"stdio\","
    echo "      \"command\": \"node\","
    echo "      \"args\": [\"$GATEWAY_PATH\"]"
    echo "    }"
    echo "  }"
    echo ""
    echo "Add it at the root level of the JSON file."
    exit 1
fi

echo ""
echo "🎉 Claude Code is now configured to use the MCP Gateway!"
echo ""
echo "📊 The gateway manages these servers:"
echo "   - GitHub, Cloudflare, Brave Search, Firecrawl"
echo "   - ElevenLabs, Context7, Chrome DevTools"
echo "   - Filesystem, Memory, Docker, Puppeteer"
echo "   - Sequential Thinking, Desktop Commander"
echo "   - Plus 10+ more configurable servers!"
echo ""
echo "⚠️  IMPORTANT: Restart Claude Code for changes to take effect"
echo ""
echo "🧪 Test by starting a new Claude Code session and asking:"
echo "   - 'What MCP tools do you have available?'"
echo "   - 'Search GitHub for TypeScript projects'"
echo "   - 'Search the web for MCP servers'"
echo ""
echo "📁 Your backup config is saved at:"
echo "   $BACKUP_PATH"
echo ""
echo "🔄 To restore your old config:"
echo "   cp \"$BACKUP_PATH\" \"$CONFIG_PATH\""
echo ""
echo "⚙️  To customize which servers are enabled:"
echo "   Edit: $(dirname $0)/config.json"
echo "   Add API keys to: $(dirname $0)/.env"
echo ""
