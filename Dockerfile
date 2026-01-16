# Multi-stage build for MCP Gateway
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src/ ./src/

# Build TypeScript
RUN npm run build

# Production image
FROM node:20-alpine

WORKDIR /app

# Install Docker CLI for Docker-based MCP servers (like GitHub)
RUN apk add --no-cache docker-cli

# Install Python and pipx for servers that need it (like ElevenLabs which uses uvx)
RUN apk add --no-cache python3 py3-pip && \
    pip3 install --break-system-packages pipx

# Create uvx wrapper (uvx is essentially 'pipx run')
RUN echo '#!/bin/sh' > /usr/local/bin/uvx && \
    echo 'exec pipx run "$@"' >> /usr/local/bin/uvx && \
    chmod +x /usr/local/bin/uvx

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Install MCP servers that have npx/uvx issues globally
RUN npm install -g @cloudflare/mcp-server-cloudflare && \
    pipx install elevenlabs-mcp

# Copy built application
COPY --from=builder /app/dist ./dist

# Copy configuration template
COPY config.json ./

# Create directory for user data
RUN mkdir -p /data

# Set environment variables (running as root for uvx/pipx compatibility)
ENV HOME=/root
ENV PATH="/root/.local/bin:$PATH"

# Note: Running as root to allow uvx/pipx to work properly
# For production, consider using a dedicated non-root user with proper permissions

# Copy and make the start script executable
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Start the gateway
CMD ["/app/start.sh"]
