#!/bin/bash
# Start MCP Gateway with Cloudflare Tunnel
# Usage: ./start-gateway.sh [config-file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG="${1:-config.json}"
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

echo "🚀 Starting MCP Gateway..."
echo "   Config: $CONFIG"

# Kill any existing processes
pkill -f "node dist/index.js" 2>/dev/null || true
pkill -f "cloudflared tunnel --url" 2>/dev/null || true
sleep 2

# Start gateway
echo "📡 Starting gateway server..."
node dist/index.js "$CONFIG" 2>&1 | tee "$LOG_DIR/gateway.log" &
GATEWAY_PID=$!

# Wait for gateway to be ready
echo "⏳ Waiting for gateway to start..."
for i in {1..30}; do
  if curl -s http://127.0.0.1:3100/health > /dev/null 2>&1; then
    echo "✅ Gateway is ready!"
    break
  fi
  sleep 1
done

# Check if we have cloudflared credentials for named tunnel
if [ -f ~/.cloudflared/cert.pem ]; then
  echo "🔐 Found Cloudflare credentials, using named tunnel..."
  # Check for existing tunnel config
  if [ -f ~/.cloudflared/config.yml ]; then
    cloudflared tunnel run 2>&1 | tee "$LOG_DIR/tunnel.log" &
  else
    echo "⚠️  No tunnel config found. Run: cloudflared tunnel create mcp-gateway"
    echo "   Falling back to quick tunnel..."
    cloudflared tunnel --url http://127.0.0.1:3100 2>&1 | tee "$LOG_DIR/tunnel.log" &
  fi
else
  echo "🌐 Using quick tunnel (no Cloudflare login)..."
  cloudflared tunnel --url http://127.0.0.1:3100 2>&1 | tee "$LOG_DIR/tunnel.log" &
fi

TUNNEL_PID=$!

# Wait for tunnel URL
echo "⏳ Waiting for tunnel URL..."
sleep 5
TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' "$LOG_DIR/tunnel.log" 2>/dev/null | head -1)

if [ -n "$TUNNEL_URL" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  🎉 MCP Gateway is running!"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  echo "  Public URL:  $TUNNEL_URL/mcp"
  echo "  Health:      $TUNNEL_URL/health"
  echo ""
  echo "  Configure remote clients with:"
  echo "  {"
  echo "    \"mcpServers\": {"
  echo "      \"gateway\": {"
  echo "        \"url\": \"$TUNNEL_URL/mcp\""
  echo "      }"
  echo "    }"
  echo "  }"
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  echo "Press Ctrl+C to stop..."
fi

# Wait for both processes
trap "kill $GATEWAY_PID $TUNNEL_PID 2>/dev/null" EXIT
wait
