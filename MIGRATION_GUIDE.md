# MCP Gateway Migration Guide

## Overview
Migrate the MCP Gateway from local MacBook Pro to a dedicated system (VPS, cloud server, or dedicated machine).

---

## Pre-Migration Checklist

### 1. **Files to Back Up**
```bash
# Navigate to project directory
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# Create migration package
tar -czf mcp-gateway-migration.tar.gz \
  docker-compose.yml \
  Dockerfile \
  config.json \
  .env \
  package.json \
  package-lock.json \
  tsconfig.json \
  src/ \
  dist/ \
  *.md
```

### 2. **Export Docker Image**
```bash
# Save the image to a tar file
docker save mcp-gateway:latest -o mcp-gateway-image.tar

# Compress it (optional, saves space)
gzip mcp-gateway-image.tar
```

### 3. **Backup Data Volume**
```bash
# Export the persistent data volume
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v $(pwd):/backup \
  alpine tar -czf /backup/gateway-data-backup.tar.gz /data
```

### 4. **Document Current State**
```bash
# Export current environment variables (REDACTED - secure handling needed)
docker inspect mcp-gateway > mcp-gateway-config-backup.json

# Get current running status
docker ps -a | grep mcp-gateway > mcp-gateway-status.txt
```

---

## Target System Requirements

### Minimum Specifications
- **OS**: Linux (Ubuntu 22.04+ or Debian 11+ recommended)
- **CPU**: 2 cores minimum
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 10GB for image + data
- **Architecture**: ARM64 (current build) OR x86_64 (requires rebuild)

### Software Requirements
- Docker Engine 24.0+
- Docker Compose 2.20+
- (Optional) Nginx for reverse proxy if exposing HTTP endpoints

---

## Migration Steps

### Step 1: Prepare Target System

```bash
# SSH into target system
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version

# Add user to docker group (optional)
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### Step 2: Transfer Files

```bash
# From your Mac, transfer the migration package
scp mcp-gateway-migration.tar.gz user@your-server-ip:/home/user/
scp mcp-gateway-image.tar.gz user@your-server-ip:/home/user/
scp gateway-data-backup.tar.gz user@your-server-ip:/home/user/

# SSH into target server
ssh user@your-server-ip

# Extract project files
mkdir -p ~/mcp-gateway
cd ~/mcp-gateway
tar -xzf ~/mcp-gateway-migration.tar.gz

# Load Docker image
docker load -i ~/mcp-gateway-image.tar.gz
```

### Step 3: Restore Data Volume

```bash
# Create the volume
docker volume create mcp-server-gateway_gateway-data

# Restore data
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd / && tar -xzf /backup/gateway-data-backup.tar.gz"
```

### Step 4: Configure Environment

```bash
# Edit .env file with correct paths and credentials
nano .env

# Verify config.json paths are correct for new system
nano config.json
```

**Important**: Update any local file paths in `.env` and `config.json` to match the new system.

### Step 5: Architecture Considerations

**If target system is x86_64** (different from your ARM64 Mac):

```bash
# Rebuild the image on the target system
cd ~/mcp-gateway
docker compose build --no-cache

# Verify new image
docker images | grep mcp-gateway
```

**If target system is ARM64** (same as Mac):
```bash
# Image should work as-is
docker images | grep mcp-gateway
```

### Step 6: Start the Gateway

```bash
# Start the container
cd ~/mcp-gateway
docker compose up -d

# Verify it's running
docker ps | grep mcp-gateway

# Check logs
docker logs -f mcp-gateway
```

### Step 7: Test Functionality

```bash
# Check if the gateway is responsive
docker exec -it mcp-gateway node -e "console.log('Gateway is running')"

# Test with MCP client (if you have one configured)
# Or verify through Claude Desktop connection
```

---

## Post-Migration

### 1. **Verify All Servers Are Connected**
Check the logs to ensure all configured MCP servers are connected:
```bash
docker logs mcp-gateway | grep -i "connected"
```

### 2. **Set Up Monitoring** (Optional)
```bash
# Install monitoring agent (e.g., Portainer, Grafana)
# Or use simple health check
docker stats mcp-gateway
```

### 3. **Configure Automatic Backups**
```bash
# Create backup script
cat > ~/backup-mcp-gateway.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/user/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup data volume
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar -czf /backup/gateway-data-$DATE.tar.gz /data

# Keep only last 7 days of backups
find $BACKUP_DIR -name "gateway-data-*.tar.gz" -mtime +7 -delete

echo "Backup completed: gateway-data-$DATE.tar.gz"
EOF

chmod +x ~/backup-mcp-gateway.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/user/backup-mcp-gateway.sh") | crontab -
```

### 4. **Configure Firewall** (if needed)
```bash
# If gateway needs external access
sudo ufw allow 22/tcp    # SSH
# Add any other ports your gateway exposes
```

### 5. **Update Claude Desktop Configuration**
If Claude Desktop connects to this gateway, update its configuration to point to the new server.

---

## Rollback Plan

If migration fails:

```bash
# Stop the container on new system
docker compose down

# Keep your Mac container running (it's already stopped for migration)
# Or restart it:
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
docker compose up -d
```

---

## Security Considerations

### 1. **Secure the .env File**
```bash
# Set restrictive permissions
chmod 600 .env

# Never commit to git
echo ".env" >> .gitignore
```

### 2. **API Keys in .env**
Your `.env` contains sensitive API keys for:
- Cloudflare
- GitHub
- Firecrawl
- Neon Database
- Twilio
- ElevenLabs
- Brave Search
- Context7

**Recommendation**: Use a secrets manager (HashiCorp Vault, AWS Secrets Manager, etc.) instead of plain-text `.env` files in production.

### 3. **Network Security**
```bash
# Use Docker network isolation
# Gateway should only expose necessary ports
# Consider using SSH tunnels or VPN for remote access
```

---

## Architecture-Specific Notes

### Current Image: ARM64 (Apple Silicon)
Your current image was built on ARM64 (Apple Silicon Mac).

**Option A**: Deploy to ARM64 server (AWS Graviton, Oracle Cloud Ampere, etc.)
- ✅ No rebuild needed
- ✅ Faster deployment
- ✅ Same performance characteristics

**Option B**: Deploy to x86_64 server (most common)
- ⚠️ Requires rebuild on target system
- ⚠️ Image size may differ slightly
- ✅ Wider hosting options

---

## Recommended Hosting Providers

### Budget-Friendly ARM64 Options
1. **Oracle Cloud** - Always Free tier with ARM instances
2. **Hetzner** - ARM64 VPS from €4.49/month
3. **Scaleway** - ARM64 instances from €0.10/hour

### x86_64 Options
1. **DigitalOcean** - Droplets from $6/month
2. **Linode** - VPS from $5/month
3. **Vultr** - Cloud Compute from $6/month
4. **Hetzner** - VPS from €4.15/month

### Considerations
- **Latency**: Choose region close to your location
- **Uptime**: Look for 99.9%+ SLA
- **Support**: 24/7 support for production systems
- **Backups**: Automatic backup options

---

## Estimated Downtime

- **File transfer**: 5-15 minutes (depends on bandwidth)
- **Image load & volume restore**: 5-10 minutes
- **Configuration & startup**: 2-5 minutes
- **Testing & verification**: 5-10 minutes

**Total**: 20-40 minutes

To minimize downtime:
1. Prepare target system fully before stopping Mac container
2. Transfer files in advance
3. Only stop Mac container when ready to switch
4. Have rollback plan ready

---

## Automation Script (Full Migration)

```bash
#!/bin/bash
# run-migration.sh - Execute on your Mac

set -e

TARGET_HOST="user@your-server-ip"
TARGET_DIR="/home/user/mcp-gateway"

echo "=== MCP Gateway Migration Script ==="

# Step 1: Create migration package
echo "[1/6] Creating migration package..."
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
tar -czf /tmp/mcp-gateway-migration.tar.gz \
  docker-compose.yml Dockerfile config.json .env \
  package*.json tsconfig.json src/ dist/

# Step 2: Export Docker image
echo "[2/6] Exporting Docker image..."
docker save mcp-gateway:latest | gzip > /tmp/mcp-gateway-image.tar.gz

# Step 3: Backup data volume
echo "[3/6] Backing up data volume..."
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v /tmp:/backup \
  alpine tar -czf /backup/gateway-data-backup.tar.gz /data

# Step 4: Transfer to target
echo "[4/6] Transferring files to target server..."
scp /tmp/mcp-gateway-*.tar.gz $TARGET_HOST:/tmp/
scp /tmp/gateway-data-backup.tar.gz $TARGET_HOST:/tmp/

# Step 5: Execute remote setup
echo "[5/6] Setting up on target server..."
ssh $TARGET_HOST << 'ENDSSH'
  set -e
  mkdir -p ~/mcp-gateway
  cd ~/mcp-gateway
  tar -xzf /tmp/mcp-gateway-migration.tar.gz
  docker load -i /tmp/mcp-gateway-image.tar.gz
  docker volume create mcp-server-gateway_gateway-data
  docker run --rm \
    -v mcp-server-gateway_gateway-data:/data \
    -v /tmp:/backup \
    alpine sh -c "cd / && tar -xzf /backup/gateway-data-backup.tar.gz"
  docker compose up -d
  docker ps | grep mcp-gateway
ENDSSH

# Step 6: Verify
echo "[6/6] Verifying deployment..."
ssh $TARGET_HOST "docker logs --tail 50 mcp-gateway"

echo "=== Migration Complete ==="
echo "Verify functionality before stopping local container"
```

---

## Support & Troubleshooting

### Common Issues

**Issue**: Container fails to start
```bash
# Check logs
docker logs mcp-gateway

# Verify volume exists
docker volume ls | grep gateway-data

# Check permissions
docker exec -it mcp-gateway ls -la /data
```

**Issue**: MCP servers not connecting
```bash
# Verify environment variables
docker exec -it mcp-gateway env | grep -i api

# Test individual server connections
# Check config.json for correct paths
```

**Issue**: Out of memory
```bash
# Check container resource usage
docker stats mcp-gateway

# Adjust memory limits in docker-compose.yml
# Or upgrade server specs
```

---

## Next Steps After Migration

1. ✅ Stop local Mac container: `docker compose down`
2. ✅ Update Claude Desktop config to use new server
3. ✅ Set up monitoring/alerting
4. ✅ Configure automated backups
5. ✅ Document new server access details
6. ✅ Test all MCP server integrations
7. ✅ Set up SSL/TLS if exposing HTTP endpoints
8. ✅ Configure log rotation

---

## Maintenance

### Regular Tasks
- **Weekly**: Check logs for errors
- **Monthly**: Update Docker images and base OS
- **Quarterly**: Review and rotate API keys
- **As needed**: Scale resources based on usage

### Monitoring Commands
```bash
# Check container status
docker ps

# View resource usage
docker stats mcp-gateway

# Check logs
docker logs -f mcp-gateway

# Check disk usage
docker system df

# Clean up old images/containers
docker system prune -a
```

---

*Migration guide created: 2025-11-10*
*Target: Dedicated system (non-laptop deployment)*
