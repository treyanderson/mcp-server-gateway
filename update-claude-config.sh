#!/bin/bash
# Update Claude Desktop configuration to use MCP Gateway

set -e

GATEWAY_PATH="$(cd "$(dirname "$0")" && pwd)/dist/index.js"
CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

echo "🔧 MCP Gateway Configuration Updater"
echo "====================================="
echo ""

# Check if gateway is built
if [ ! -f "$GATEWAY_PATH" ]; then
    echo "❌ Gateway not built. Run 'npm run build' first."
    exit 1
fi

echo "✅ Gateway found at: $GATEWAY_PATH"
echo ""

# Backup existing config
if [ -f "$CONFIG_PATH" ]; then
    BACKUP_PATH="${CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📦 Backing up existing config to:"
    echo "   $BACKUP_PATH"
    cp "$CONFIG_PATH" "$BACKUP_PATH"
    echo ""
fi

# Create new config with gateway only
echo "📝 Creating new Claude Desktop config with gateway..."
cat > "$CONFIG_PATH" << EOF
{
  "mcpServers": {
    "mcp-gateway": {
      "command": "node",
      "args": [
        "$GATEWAY_PATH"
      ]
    }
  }
}
EOF

echo "✅ Configuration updated!"
echo ""
echo "📋 Your Claude Desktop config now contains:"
cat "$CONFIG_PATH"
echo ""
echo "⚠️  IMPORTANT: Completely quit and restart Claude Desktop"
echo ""
echo "🧪 Test by asking Claude:"
echo "   - 'What tools do you have available?'"
echo "   - 'Search GitHub for MCP servers'"
echo "   - 'Search the web for TypeScript tutorials'"
echo ""
echo "📊 Your backup config is saved at:"
echo "   $BACKUP_PATH"
echo ""
echo "🔄 To restore your old config:"
echo "   cp \"$BACKUP_PATH\" \"$CONFIG_PATH\""
echo ""
