#!/bin/bash
# MCP Gateway Setup Script for DGX Spark
# Usage: curl -sL https://raw.githubusercontent.com/treyanderson/mcp-server-gateway/master/setup-dgx.sh | bash

set -e

echo "=========================================="
echo "MCP Gateway Setup for DGX Spark"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running on Linux
if [[ "$(uname)" != "Linux" ]]; then
    error "This script is for Linux (DGX Spark). Use setup.sh for macOS."
fi

# Variables
INSTALL_DIR="${HOME}/mcp-server-gateway"
NODE_VERSION="20"

# 1. Install Node.js via nvm if not present
info "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    info "Installing nvm and Node.js ${NODE_VERSION}..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install ${NODE_VERSION}
    nvm use ${NODE_VERSION}
    nvm alias default ${NODE_VERSION}
else
    info "Node.js already installed: $(node --version)"
fi

# Ensure nvm is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 2. Clone repository
info "Cloning MCP Gateway repository..."
if [ -d "$INSTALL_DIR" ]; then
    warn "Directory exists. Pulling latest changes..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone https://github.com/treyanderson/mcp-server-gateway.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Install dependencies and build
info "Installing dependencies..."
npm install

info "Building project..."
npm run build

# 4. Create .env file if not exists
if [ ! -f .env ]; then
    info "Creating .env file from example..."
    cp .env.example .env
    warn "Edit .env file to add your API keys: nano ${INSTALL_DIR}/.env"
fi

# 5. Install PM2 for process management
info "Installing PM2..."
npm install -g pm2

# 6. Install cloudflared (detect architecture)
info "Installing cloudflared..."
if ! command -v cloudflared &> /dev/null || ! cloudflared --version &> /dev/null; then
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    fi
    info "Downloading cloudflared for ${ARCH}..."
    sudo curl -L "$CLOUDFLARED_URL" -o /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    info "cloudflared installed successfully"
else
    info "cloudflared already installed: $(cloudflared --version)"
fi

# 7. Create PM2 ecosystem file (.cjs for ES module compatibility)
info "Creating PM2 ecosystem file..."
cat > ecosystem.config.cjs << 'EOFPM2'
module.exports = {
  apps: [{
    name: 'mcp-gateway',
    script: 'dist/index.js',
    cwd: process.env.HOME + '/mcp-server-gateway',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOFPM2

# 8. Create systemd service files
info "Creating systemd service files..."

# MCP Gateway service
sudo tee /etc/systemd/system/mcp-gateway.service > /dev/null << EOFSVC
[Unit]
Description=MCP Gateway Server
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=$(which node) ${INSTALL_DIR}/dist/index.js
Restart=always
RestartSec=10
Environment=PATH=$(dirname $(which node)):/usr/bin:/bin
Environment=HOME=${HOME}

[Install]
WantedBy=multi-user.target
EOFSVC

echo ""
echo "=========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit your environment variables:"
echo "   nano ${INSTALL_DIR}/.env"
echo ""
echo "2. Start the gateway (choose one):"
echo "   Option A - PM2 (recommended):"
echo "     cd ${INSTALL_DIR}"
echo "     pm2 start ecosystem.config.cjs"
echo "     pm2 save"
echo "     pm2 startup  # Follow instructions"
echo ""
echo "   Option B - Systemd:"
echo "     sudo systemctl daemon-reload"
echo "     sudo systemctl enable mcp-gateway"
echo "     sudo systemctl start mcp-gateway"
echo ""
echo "3. Setup Cloudflare Tunnel (for remote access):"
echo "   cloudflared tunnel login"
echo "   cloudflared tunnel create dgx-mcp"
echo "   # Then configure ~/.cloudflared/config.yml"
echo ""
echo "4. Test the gateway:"
echo "   curl http://localhost:3100/health"
echo ""
echo "=========================================="
