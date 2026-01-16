# Quick Migration Steps - MCP Gateway

## TL;DR - Fast Migration

### On Your Mac (Source)
```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# 1. Export everything
docker save mcp-gateway:latest | gzip > ~/mcp-gateway-image.tar.gz
docker run --rm -v mcp-server-gateway_gateway-data:/data -v $(pwd):/backup alpine tar -czf /backup/gateway-data-backup.tar.gz /data
tar -czf ~/mcp-gateway-project.tar.gz .

# 2. Transfer to new server
scp ~/mcp-gateway-*.tar.gz user@new-server:/tmp/
scp gateway-data-backup.tar.gz user@new-server:/tmp/
```

### On New Server (Target)
```bash
# 1. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

# 2. Setup project
mkdir -p ~/mcp-gateway && cd ~/mcp-gateway
tar -xzf /tmp/mcp-gateway-project.tar.gz

# 3. Load image and data
docker load -i /tmp/mcp-gateway-image.tar.gz
docker volume create mcp-server-gateway_gateway-data
docker run --rm -v mcp-server-gateway_gateway-data:/data -v /tmp:/backup alpine sh -c "cd / && tar -xzf /backup/gateway-data-backup.tar.gz"

# 4. Start
docker compose up -d

# 5. Verify
docker logs mcp-gateway
```

---

## What You're Migrating

### Container Details
- **Name**: `mcp-gateway`
- **ID**: `c252b602dd66`
- **Image**: `mcp-gateway:latest` (622MB)
- **Architecture**: ARM64 (Apple Silicon)

### Critical Components
1. **Project files**: `/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway`
2. **Docker image**: `mcp-gateway:latest`
3. **Data volume**: `mcp-server-gateway_gateway-data`
4. **Config**: `config.json` (server definitions)
5. **Secrets**: `.env` (API keys for 10+ services)

### Important Paths
- **Config mount**: `./config.json` → `/app/config.json` (read-only)
- **Data mount**: `gateway-data` volume → `/data` (persistent)

---

## Architecture Warning

Your current image is **ARM64** (Apple Silicon).

**Deploying to x86_64 server?** You'll need to rebuild:
```bash
# On the x86_64 server
cd ~/mcp-gateway
docker compose build --no-cache
docker compose up -d
```

**Deploying to ARM64 server?** Image works as-is:
```bash
docker compose up -d
```

---

## Environment Variables to Preserve

Your `.env` contains API keys for:
- ✅ Cloudflare (API token + Account ID)
- ✅ GitHub (Personal Access Token)
- ✅ Firecrawl (API key)
- ✅ Neon Database (API key)
- ✅ Twilio (Account SID + Auth Token)
- ✅ ElevenLabs (API key)
- ✅ Brave Search (API key)
- ✅ Context7 (API key)

**⚠️ Keep `.env` secure** - Never commit to git, set `chmod 600`.

---

## Quick Hosting Recommendations

### ARM64 (No rebuild needed)
- **Oracle Cloud**: Free ARM instances
- **Hetzner**: ARM64 VPS €4.49/month
- **Scaleway**: ARM instances €0.10/hour

### x86_64 (Rebuild required)
- **DigitalOcean**: $6/month Droplets
- **Linode**: $5/month VPS
- **Hetzner**: €4.15/month VPS

---

## Automated Migration Script

Save this as `migrate.sh`:

```bash
#!/bin/bash
TARGET="user@your-server-ip"

# Export from Mac
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
docker save mcp-gateway:latest | gzip > /tmp/image.tar.gz
docker run --rm -v mcp-server-gateway_gateway-data:/data -v /tmp:/backup alpine tar -czf /backup/data.tar.gz /data
tar -czf /tmp/project.tar.gz .

# Transfer
scp /tmp/{image,project,data}.tar.gz $TARGET:/tmp/

# Setup on remote
ssh $TARGET << 'EOF'
  mkdir -p ~/mcp-gateway && cd ~/mcp-gateway
  tar -xzf /tmp/project.tar.gz
  docker load -i /tmp/image.tar.gz
  docker volume create mcp-server-gateway_gateway-data
  docker run --rm -v mcp-server-gateway_gateway-data:/data -v /tmp:/backup alpine sh -c "cd / && tar -xzf /backup/data.tar.gz"
  docker compose up -d
  docker logs --tail 50 mcp-gateway
EOF
```

Run with: `chmod +x migrate.sh && ./migrate.sh`

---

## Post-Migration Checklist

- [ ] Container running: `docker ps | grep mcp-gateway`
- [ ] Logs clean: `docker logs mcp-gateway | tail -50`
- [ ] Volume mounted: `docker inspect mcp-gateway | grep -A5 Mounts`
- [ ] All MCP servers connected: Check logs for connection messages
- [ ] Test with Claude Desktop (if applicable)
- [ ] Set up backups: `crontab -e` (add daily backup job)
- [ ] Stop Mac container: `docker compose down` (on Mac)

---

## Rollback

If something goes wrong:
```bash
# On Mac
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
docker compose up -d
```

---

## Support

For detailed instructions, see: `MIGRATION_GUIDE.md`

For Docker issues:
```bash
docker logs mcp-gateway     # Check errors
docker system df            # Check disk space
docker stats mcp-gateway    # Check resources
```
