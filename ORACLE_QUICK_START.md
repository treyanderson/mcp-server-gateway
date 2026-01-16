# Oracle Cloud Quick Start - MCP Gateway

**TL;DR**: Get your MCP Gateway running on Oracle Cloud in 30 minutes.

---

## What You'll Get

- ✅ **Always Free** Oracle Cloud ARM64 instance (4 cores + 24GB RAM)
- ✅ **No rebuild** needed (ARM64 to ARM64)
- ✅ **Automated deployment** with one command
- ✅ **24/7 uptime** (no laptop needed)
- ✅ **Production-ready** security hardening

---

## Prerequisites

- [ ] Oracle Cloud account (create at https://www.oracle.com/cloud/free/)
- [ ] Docker running on your Mac
- [ ] MCP Gateway container running locally
- [ ] SSH key ready (`~/.ssh/oracle-mcp-gateway.key`)

---

## Three-Step Deployment

### Step 1: Create Oracle Cloud Instance (15 min)

Follow: **`ORACLE_CLOUD_SETUP.md`** - Sections 1-4 (Part 1-4)

**Quick summary**:
1. Sign up for Oracle Cloud
2. Create compute instance:
   - **Shape**: VM.Standard.A1.Flex (ARM64)
   - **OCPUs**: 2
   - **Memory**: 12GB
   - **Image**: Ubuntu 22.04
   - **Network**: Public IP + SSH access
3. Save SSH key and public IP address
4. Configure security list (allow port 22)

**Result**: Running Ubuntu instance with public IP

---

### Step 2: Run Automated Deployment (10 min)

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# Run automated deployment script
./deploy-to-oracle.sh YOUR_ORACLE_IP

# Example:
./deploy-to-oracle.sh 150.230.45.123
```

**What this does**:
- ✅ Exports Docker image from Mac
- ✅ Exports data volume from Mac
- ✅ Exports project files from Mac
- ✅ Transfers everything to Oracle Cloud
- ✅ Loads image and data on Oracle Cloud
- ✅ Starts container
- ✅ Verifies deployment

**Result**: MCP Gateway running on Oracle Cloud

---

### Step 3: Verify and Secure (5 min)

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_ORACLE_IP

# Check container is running
docker ps | grep mcp-gateway

# View logs
docker logs -f mcp-gateway
```

**Look for**:
- ✅ Container status: "Up"
- ✅ No errors in logs
- ✅ All MCP servers connected

**Security** (run immediately):
```bash
# Enable firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable

# Set up Fail2Ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Secure .env file
chmod 600 ~/mcp-gateway/.env
```

**Result**: Secure, production-ready MCP Gateway

---

## What If Something Goes Wrong?

### Issue: SSH connection fails

```bash
# Check instance is running (Oracle Console)
# Verify security list allows port 22
# Check SSH key permissions
chmod 600 ~/.ssh/oracle-mcp-gateway.key

# Try verbose SSH
ssh -v -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_ORACLE_IP
```

### Issue: Container won't start

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_ORACLE_IP

# Check logs
docker logs mcp-gateway

# Verify image loaded
docker images | grep mcp-gateway

# Verify volume exists
docker volume ls | grep gateway-data

# Try manual start
cd ~/mcp-gateway
docker compose up
```

### Issue: Script fails during transfer

```bash
# Check disk space on Mac
df -h /tmp

# Check upload speed (large files = slow transfer)
# Re-run script - it will resume from where it failed
./deploy-to-oracle.sh YOUR_ORACLE_IP
```

---

## Post-Deployment

### Stop Mac Container

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
docker compose down
```

### Update Claude Desktop

Point Claude Desktop to your Oracle Cloud instance:
- Option 1: SSH tunnel (most secure)
- Option 2: Direct connection (if exposed)
- Option 3: Stdio over SSH

See: **`ORACLE_CLOUD_SETUP.md`** - Part 12

### Set Up Backups

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_ORACLE_IP

# Create backup script
cat > ~/backup-mcp-gateway.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar -czf /backup/gateway-data-$DATE.tar.gz /data
find $BACKUP_DIR -name "gateway-data-*.tar.gz" -mtime +7 -delete
echo "Backup completed: gateway-data-$DATE.tar.gz"
EOF

chmod +x ~/backup-mcp-gateway.sh

# Test it
~/backup-mcp-gateway.sh

# Schedule daily backups (2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup-mcp-gateway.sh") | crontab -
```

---

## Essential Commands

### SSH Access
```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_ORACLE_IP
```

### Container Management
```bash
# View logs
docker logs -f mcp-gateway

# Restart container
docker restart mcp-gateway

# Stop container
docker compose down

# Start container
docker compose up -d

# Check status
docker ps

# Resource usage
docker stats mcp-gateway
```

### System Maintenance
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Check disk space
df -h

# Check memory
free -h

# Check firewall
sudo ufw status

# Check failed SSH attempts
sudo grep "Failed password" /var/log/auth.log | tail -20
```

---

## Cost Breakdown

**Monthly Cost**: **$0.00** (Always Free)

### What's Included
- ✅ 4 ARM cores (Ampere A1)
- ✅ 24GB RAM
- ✅ 50GB storage (up to 200GB free)
- ✅ 10TB bandwidth/month
- ✅ 1 public IPv4
- ✅ 99.9% uptime SLA

### No Hidden Costs
- ❌ No egress charges (first 10TB)
- ❌ No compute charges
- ❌ No storage charges (up to 200GB)
- ❌ No support charges

---

## Performance

### Expected Performance (2 OCPU + 12GB RAM)
- **Latency**: 20-50ms
- **Throughput**: 100+ concurrent connections
- **Reliability**: 99.9% uptime
- **Network**: 1Gbps+

### Comparison to Mac
- ✅ **Always on** (no sleep/restarts)
- ✅ **Better uptime** (enterprise infrastructure)
- ✅ **Same performance** (ARM64 to ARM64)
- ✅ **Lower power** (no laptop battery drain)

---

## Documentation Map

**Need more details? See these guides**:

1. **`ORACLE_CLOUD_SETUP.md`**
   - Complete walkthrough (Parts 1-12)
   - Detailed explanations
   - Troubleshooting
   - Advanced configuration

2. **`ORACLE_SECURITY_CHECKLIST.md`**
   - Complete security hardening
   - Compliance checklist
   - Monitoring setup
   - Incident response

3. **`deploy-to-oracle.sh`**
   - Automated deployment script
   - One-command migration
   - Progress tracking

4. **`MIGRATION_GUIDE.md`**
   - General migration guide
   - Multi-platform support
   - Detailed procedures

5. **`QUICK_MIGRATION_STEPS.md`**
   - Fast migration commands
   - TL;DR version

---

## Support

### Getting Help

**Script issues**:
```bash
./deploy-to-oracle.sh --help
# Or review script source code
```

**Oracle Cloud issues**:
- Console: https://cloud.oracle.com
- Docs: https://docs.oracle.com/iaas/
- Forums: https://community.oracle.com/cloud/

**Container issues**:
```bash
# Check logs first
docker logs mcp-gateway

# Review project docs
cat ~/mcp-gateway/README.md
```

---

## Next Steps

### After Successful Deployment

1. ✅ **Test connectivity** from Claude Desktop
2. ✅ **Complete security checklist** (ORACLE_SECURITY_CHECKLIST.md)
3. ✅ **Set up monitoring** (Optional: Grafana, Prometheus)
4. ✅ **Document your setup** (credentials, IP, etc.)
5. ✅ **Remove Mac container** (`docker compose down`)

### Weekly Maintenance

- [ ] Review logs for errors
- [ ] Check resource usage
- [ ] Verify backups are running
- [ ] Check for security updates

### Monthly Maintenance

- [ ] Apply system updates
- [ ] Review security logs
- [ ] Test backup restoration
- [ ] Update documentation

---

## FAQ

**Q: Do I need a credit card?**
A: Oracle usually requires one for verification, but won't charge for Always Free resources.

**Q: Can I use x86_64 instead of ARM64?**
A: Yes, but you'll need to rebuild the image. Use `VM.Standard.E2.1.Micro` (free tier x86_64).

**Q: What if I exceed free tier limits?**
A: Oracle will notify you but won't auto-upgrade. You control spending.

**Q: Can I scale up later?**
A: Yes, upgrade to paid instance anytime. Free tier resources remain free.

**Q: How do I delete everything?**
A: Oracle Console → Compute → Instances → Terminate Instance

**Q: Can I have multiple instances?**
A: Yes, free tier allows up to 4 OCPUs total across all instances.

**Q: What about bandwidth limits?**
A: 10TB/month outbound free. After that, $0.0085/GB.

---

## Success Checklist

- [ ] Oracle Cloud account created
- [ ] Instance provisioned and running
- [ ] SSH access working
- [ ] Deployment script completed successfully
- [ ] Container running on Oracle Cloud
- [ ] Logs show no errors
- [ ] All MCP servers connected
- [ ] Firewall enabled
- [ ] Fail2Ban installed
- [ ] Backups configured
- [ ] Claude Desktop updated
- [ ] Mac container stopped
- [ ] Documentation updated

**All checked? Congratulations! 🎉**

Your MCP Gateway is now production-ready on Oracle Cloud!

---

*Quick start guide created: 2025-11-10*
*Estimated time: 30 minutes*
*Skill level: Intermediate*
