#!/bin/bash
# MCP Gateway Setup Script

set -e

echo "🚀 MCP Gateway Setup"
echo "===================="
echo ""

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18 or higher."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18 or higher is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) detected"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env and add your API keys!"
else
    echo "✅ .env file already exists"
fi
echo ""

# Build the project
echo "🔨 Building TypeScript project..."
npm run build
echo ""

echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env and add your API keys"
echo "2. Review config.json and disable servers you don't need"
echo "3. Run 'npm start' to start the gateway"
echo "4. Add the gateway to your Claude Desktop config:"
echo ""
echo "   {\"mcpServers\": {"
echo "     \"mcp-gateway\": {"
echo "       \"command\": \"node\","
echo "       \"args\": [\"$(pwd)/dist/index.js\"]"
echo "     }"
echo "   }}"
echo ""
