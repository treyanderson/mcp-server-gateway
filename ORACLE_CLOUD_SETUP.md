# Oracle Cloud Setup Guide - MCP Gateway

Complete walkthrough for deploying your MCP Gateway to Oracle Cloud's Always Free ARM64 instance.

---

## Why Oracle Cloud?

- ✅ **Always Free Tier** - 4 ARM-based Ampere A1 cores + 24GB RAM forever
- ✅ **ARM64 Native** - Your image runs without rebuild
- ✅ **No Credit Card Required** (for free tier, but often needed for verification)
- ✅ **Enterprise Infrastructure** - Reliable uptime and performance

---

## Part 1: Oracle Cloud Account Setup

### Step 1: Create Account

1. Go to: https://www.oracle.com/cloud/free/
2. Click **"Start for free"**
3. Fill in details:
   - Email address
   - Country/Territory
   - Choose **"Individual"** for account type
4. Verify email and complete registration

**Note**: Oracle may ask for credit card verification even for free tier, but won't charge unless you explicitly upgrade.

### Step 2: Initial Console Login

1. After account creation, go to: https://cloud.oracle.com/
2. Enter your **Cloud Account Name** (you chose this during signup)
3. Click **Continue**
4. Login with your credentials
5. You'll land in the **Oracle Cloud Console**

---

## Part 2: Create ARM64 Compute Instance

### Step 1: Navigate to Compute

1. Click hamburger menu (☰) top left
2. Go to: **Compute → Instances**
3. Click **"Create Instance"**

### Step 2: Configure Instance Basics

**Name**: `mcp-gateway-prod`

**Compartment**: Leave as default (root)

**Placement**: Leave as default (AD-1)

### Step 3: Choose Image and Shape

#### Image Configuration

1. Click **"Change Image"**
2. Select: **Canonical Ubuntu 22.04**
3. Click **"Select Image"**

#### Shape Configuration

1. Click **"Change Shape"**
2. Select **"Ampere"** (ARM-based)
3. Choose shape: **VM.Standard.A1.Flex**
4. Configure resources (Always Free limits):
   - **OCPUs**: 2-4 (up to 4 free)
   - **Memory**: 12-24 GB (up to 24GB free)
   - **Recommendation**: 2 OCPUs + 12GB RAM (plenty for MCP Gateway)
5. Click **"Select Shape"**

### Step 4: Networking

#### Primary VNIC Configuration

Leave defaults:
- **VCN**: (auto-created default VCN)
- **Subnet**: (auto-created public subnet)
- **Public IPv4 address**: ✅ **Assign a public IPv4 address** (checked)

#### Important: Save the VCN name
You'll need this for firewall rules. It's usually: `vcn-YYYYMMDD-HHMM`

### Step 5: SSH Keys

**Critical Step**: You need SSH access to your instance.

#### Option A: Generate New SSH Key Pair (Recommended)

1. Select **"Generate a key pair for me"**
2. Click **"Save Private Key"** → saves as `ssh-key-YYYY-MM-DD.key`
3. Click **"Save Public Key"** → saves as `ssh-key-YYYY-MM-DD.key.pub`
4. **IMPORTANT**: Store these files securely (e.g., `~/.ssh/oracle-mcp-gateway.key`)

#### Option B: Use Existing SSH Key

1. Select **"Paste public keys"** or **"Upload public key files"**
2. Paste your existing `~/.ssh/id_rsa.pub` or upload the file

### Step 6: Boot Volume

Leave defaults:
- **Boot volume size**: 50GB (free tier allows up to 200GB total)
- **Use in-transit encryption**: ✅ (checked)

### Step 7: Create Instance

1. Review all settings
2. Click **"Create"** (bottom of page)
3. Instance will provision (takes 2-3 minutes)
4. Status will change: **PROVISIONING** → **RUNNING** (orange → green)

### Step 8: Get Instance Details

Once **RUNNING**:
1. Click on instance name: `mcp-gateway-prod`
2. Note down:
   - **Public IP Address**: e.g., `150.230.45.123` ← You'll need this
   - **Username**: `ubuntu` (for Ubuntu images)

---

## Part 3: Configure Firewall Rules

Oracle Cloud has **TWO firewalls** you need to configure:
1. **OCI Security List** (cloud-level)
2. **OS Firewall** (instance-level)

### Step 1: Configure OCI Security List

1. In your instance details page, scroll to **Primary VNIC**
2. Click on the **Subnet** link (e.g., `subnet-YYYYMMDD-HHMM`)
3. Under **Security Lists**, click the security list name (e.g., `Default Security List for vcn-...`)
4. Click **"Add Ingress Rules"**

Add these rules:

#### Rule 1: SSH Access
- **Source CIDR**: `0.0.0.0/0` (or your specific IP for better security)
- **IP Protocol**: `TCP`
- **Destination Port Range**: `22`
- **Description**: `SSH access`
- Click **"Add Ingress Rules"**

#### Rule 2: Custom Ports (Optional - if gateway needs HTTP access)
Only if your MCP Gateway exposes HTTP endpoints:
- **Source CIDR**: `0.0.0.0/0` (or restrict to your IP)
- **IP Protocol**: `TCP`
- **Destination Port Range**: `3000` (or your gateway port)
- **Description**: `MCP Gateway HTTP access`
- Click **"Add Ingress Rules"**

**Note**: MCP Gateway uses stdio by default, so you may NOT need external ports exposed.

### Step 2: Configure OS Firewall (Done after SSH in)

We'll do this in Part 4 after connecting via SSH.

---

## Part 4: Connect to Your Instance

### Step 1: Set Up SSH Key Permissions (On Your Mac)

```bash
# Move the downloaded key to SSH directory
mkdir -p ~/.ssh
mv ~/Downloads/ssh-key-*.key ~/.ssh/oracle-mcp-gateway.key

# Set correct permissions (SSH requires this)
chmod 600 ~/.ssh/oracle-mcp-gateway.key
```

### Step 2: Connect via SSH

Replace `YOUR_PUBLIC_IP` with your instance's public IP:

```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_PUBLIC_IP
```

Example:
```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.230.45.123
```

**First time**: You'll see a fingerprint verification prompt, type `yes`

### Step 3: Verify Connection

Once connected, you'll see:
```
ubuntu@mcp-gateway-prod:~$
```

You're in! 🎉

---

## Part 5: Prepare the Server

### Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

This takes ~2-5 minutes.

### Step 2: Install Docker

```bash
# Install Docker using official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (no need for sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

**Expected output**: `Docker version 24.x.x, build ...`

### Step 3: Install Docker Compose

```bash
# Docker Compose is included with modern Docker
docker compose version
```

**Expected output**: `Docker Compose version v2.x.x`

### Step 4: Configure OS Firewall

```bash
# Check current firewall status
sudo iptables -L

# Oracle Cloud's Ubuntu images have iptables rules
# We need to allow traffic on ports we need

# Allow SSH (already open, but ensure)
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT

# If MCP Gateway needs HTTP port (e.g., 3000)
# sudo iptables -I INPUT -p tcp --dport 3000 -j ACCEPT

# Save rules
sudo netfilter-persistent save

# Or for iptables-persistent
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
```

### Step 5: Create Project Directory

```bash
mkdir -p ~/mcp-gateway
cd ~/mcp-gateway
```

---

## Part 6: Transfer Files from Your Mac

### Step 1: Open New Terminal on Your Mac

Keep your SSH session open, open a **new terminal window** on your Mac.

### Step 2: Export Project Files (On Your Mac)

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# Export Docker image
docker save mcp-gateway:latest | gzip > /tmp/mcp-gateway-image.tar.gz

# Export data volume
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v /tmp:/backup \
  alpine tar -czf /backup/mcp-gateway-data.tar.gz /data

# Export project files
tar -czf /tmp/mcp-gateway-project.tar.gz \
  docker-compose.yml \
  Dockerfile \
  config.json \
  .env \
  package.json \
  package-lock.json \
  tsconfig.json \
  src/ \
  dist/
```

### Step 3: Transfer to Oracle Cloud (On Your Mac)

Replace `YOUR_PUBLIC_IP` with your Oracle Cloud instance IP:

```bash
# Transfer image
scp -i ~/.ssh/oracle-mcp-gateway.key \
  /tmp/mcp-gateway-image.tar.gz \
  ubuntu@YOUR_PUBLIC_IP:/tmp/

# Transfer data backup
scp -i ~/.ssh/oracle-mcp-gateway.key \
  /tmp/mcp-gateway-data.tar.gz \
  ubuntu@YOUR_PUBLIC_IP:/tmp/

# Transfer project files
scp -i ~/.ssh/oracle-mcp-gateway.key \
  /tmp/mcp-gateway-project.tar.gz \
  ubuntu@YOUR_PUBLIC_IP:/tmp/
```

**Transfer time**: 2-10 minutes depending on your upload speed.

**Tip**: You can monitor progress with `-v` flag: `scp -v -i ...`

---

## Part 7: Deploy on Oracle Cloud

### Step 1: Extract Project Files (On Oracle Cloud SSH session)

```bash
cd ~/mcp-gateway

# Extract project
tar -xzf /tmp/mcp-gateway-project.tar.gz

# Verify files
ls -la
```

You should see: `docker-compose.yml`, `config.json`, `.env`, etc.

### Step 2: Load Docker Image

```bash
docker load -i /tmp/mcp-gateway-image.tar.gz
```

**Expected output**: `Loaded image: mcp-gateway:latest`

Verify:
```bash
docker images | grep mcp-gateway
```

### Step 3: Create and Restore Data Volume

```bash
# Create volume
docker volume create mcp-server-gateway_gateway-data

# Restore data
docker run --rm \
  -v mcp-server-gateway_gateway-data:/data \
  -v /tmp:/backup \
  alpine sh -c "cd / && tar -xzf /backup/mcp-gateway-data.tar.gz"

# Verify volume
docker volume ls | grep gateway-data
```

### Step 4: Review and Update Configuration

```bash
# Check .env file
cat .env

# Edit if needed (e.g., update paths)
nano .env

# Check config.json
cat config.json

# Edit if needed
nano config.json
```

**Important**: Ensure all paths in `config.json` and `.env` are correct for the new system.

### Step 5: Start the MCP Gateway

```bash
cd ~/mcp-gateway

# Start in detached mode
docker compose up -d
```

**Expected output**:
```
[+] Running 1/1
 ✔ Container mcp-gateway  Started
```

### Step 6: Verify Deployment

```bash
# Check container is running
docker ps

# Check logs
docker logs mcp-gateway

# Follow logs in real-time
docker logs -f mcp-gateway
```

**Look for**:
- ✅ "MCP server started"
- ✅ Connected MCP servers (GitHub, Cloudflare, etc.)
- ❌ No error messages

Press `Ctrl+C` to exit log viewing.

---

## Part 8: Configure Auto-Start on Reboot

```bash
# Docker Compose with restart: unless-stopped (already in docker-compose.yml)
# means it will auto-start on reboot

# Verify restart policy
docker inspect mcp-gateway | grep -A5 RestartPolicy
```

Should show: `"Name": "unless-stopped"`

---

## Part 9: Set Up Backups

### Step 1: Create Backup Script

```bash
nano ~/backup-mcp-gateway.sh
```

Paste this:
```bash
#!/bin/bash
BACKUP_DIR="$HOME/backups"
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
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

Make executable:
```bash
chmod +x ~/backup-mcp-gateway.sh
```

Test it:
```bash
~/backup-mcp-gateway.sh
```

### Step 2: Schedule Daily Backups

```bash
# Edit crontab
crontab -e
```

Add this line (runs daily at 2 AM UTC):
```
0 2 * * * /home/ubuntu/backup-mcp-gateway.sh >> /home/ubuntu/backup.log 2>&1
```

Save and exit.

Verify:
```bash
crontab -l
```

---

## Part 10: Security Hardening

### Step 1: Secure SSH Access

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config
```

Ensure these settings:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

### Step 2: Set Up Firewall (UFW - Alternative to iptables)

```bash
# Install UFW (if not installed)
sudo apt install ufw -y

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (CRITICAL - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow HTTP (if needed for gateway)
# sudo ufw allow 3000/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 3: Enable Automatic Security Updates

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Select **Yes** when prompted.

### Step 4: Set Up Fail2Ban (SSH Brute-Force Protection)

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Start and enable
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check status
sudo fail2ban-client status
```

---

## Part 11: Monitoring and Maintenance

### Daily Health Check

```bash
# Check container status
docker ps

# Check logs for errors
docker logs mcp-gateway | tail -50

# Check resource usage
docker stats mcp-gateway --no-stream

# Check disk space
df -h

# Check system resources
free -h
htop  # (install with: sudo apt install htop)
```

### Update Docker Image (When Needed)

```bash
cd ~/mcp-gateway

# Stop container
docker compose down

# Pull/rebuild image
docker compose pull  # if using registry
# OR rebuild locally
docker compose build

# Restart
docker compose up -d

# Verify
docker logs mcp-gateway
```

---

## Part 12: Connect Claude Desktop to Oracle Cloud Instance

### Option 1: SSH Tunnel (Recommended for Security)

If MCP Gateway uses stdio, you'll need an SSH tunnel:

**On Your Mac** (in Claude Desktop config):

```bash
# Create SSH tunnel script
cat > ~/.ssh/oracle-mcp-tunnel.sh << 'EOF'
#!/bin/bash
ssh -i ~/.ssh/oracle-mcp-gateway.key \
  -L 3000:localhost:3000 \
  ubuntu@YOUR_PUBLIC_IP \
  -N -f
EOF

chmod +x ~/.ssh/oracle-mcp-tunnel.sh

# Run tunnel
~/.ssh/oracle-mcp-tunnel.sh
```

Then configure Claude Desktop to connect to `localhost:3000`.

### Option 2: Direct Connection (If Gateway Exposes HTTP)

If you exposed port 3000 in security lists, connect directly:
- Update Claude Desktop config to use: `http://YOUR_PUBLIC_IP:3000`

### Option 3: Stdio Over SSH (Most Secure)

Claude Desktop config example:
```json
{
  "mcpServers": {
    "mcp-gateway-oracle": {
      "command": "ssh",
      "args": [
        "-i", "/Users/trey/.ssh/oracle-mcp-gateway.key",
        "ubuntu@YOUR_PUBLIC_IP",
        "docker", "exec", "-i", "mcp-gateway", "node", "dist/index.js"
      ]
    }
  }
}
```

---

## Troubleshooting

### Instance Won't Start
```bash
# Check instance logs in Oracle Console
# Go to: Compute → Instances → Your Instance → Work Requests
```

### Can't SSH In
```bash
# Verify security list allows port 22
# Check SSH key permissions: chmod 600 ~/.ssh/oracle-mcp-gateway.key
# Try verbose mode: ssh -v -i ~/.ssh/oracle-mcp-gateway.key ubuntu@IP
```

### Container Won't Start
```bash
# Check logs
docker logs mcp-gateway

# Check volume exists
docker volume ls | grep gateway-data

# Verify image loaded
docker images | grep mcp-gateway

# Check docker-compose.yml syntax
docker compose config
```

### Out of Memory
```bash
# Check memory usage
free -h

# Check Docker stats
docker stats mcp-gateway --no-stream

# If needed, increase instance RAM:
# Oracle Console → Compute → Instances → Edit Instance → Change Shape
# (Can scale up to 24GB free)
```

### Can't Access from Claude Desktop
```bash
# Verify container is running
docker ps | grep mcp-gateway

# Check security list allows your IP
# Check OS firewall: sudo ufw status

# Test connectivity from Mac
telnet YOUR_PUBLIC_IP 3000  # or your gateway port
```

---

## Cost Breakdown

### Always Free Resources Used
- ✅ **Compute**: 2 OCPUs + 12GB RAM (Free)
- ✅ **Storage**: 50GB boot volume (Free up to 200GB total)
- ✅ **Networking**: 10TB outbound/month (Free)
- ✅ **Public IP**: 1 free public IPv4

**Total Monthly Cost**: **$0.00** ✨

---

## Performance Expectations

### Oracle Cloud ARM64 (2 OCPUs + 12GB RAM)
- **MCP Gateway**: Handles 100+ concurrent connections easily
- **Latency**: ~20-50ms response time (depends on location)
- **Uptime**: 99.9%+ SLA
- **Network**: 1-10 Gbps depending on shape

**Comparison to Mac**:
- Similar or better performance
- Better uptime (no laptop sleep/restarts)
- Lower power consumption
- Better network connectivity

---

## Quick Reference Commands

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_PUBLIC_IP

# Check container status
docker ps

# View logs
docker logs -f mcp-gateway

# Restart container
docker restart mcp-gateway

# Stop container
docker compose down

# Start container
docker compose up -d

# Check resource usage
docker stats mcp-gateway

# Backup data
~/backup-mcp-gateway.sh

# Update system
sudo apt update && sudo apt upgrade -y
```

---

## Next Steps After Deployment

1. ✅ Verify all MCP servers are connected (check logs)
2. ✅ Test connectivity from Claude Desktop
3. ✅ Set up monitoring alerts (optional: install Prometheus/Grafana)
4. ✅ Document your Oracle Cloud credentials
5. ✅ Set up off-site backups (optional: OCI Object Storage)
6. ✅ Stop Mac container: `docker compose down` (on Mac)
7. ✅ Remove Mac exports to free space: `rm /tmp/mcp-gateway-*.tar.gz`

---

## Additional Resources

- **Oracle Cloud Docs**: https://docs.oracle.com/iaas/
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Docker Docs**: https://docs.docker.com/
- **Ubuntu Server Guide**: https://ubuntu.com/server/docs

---

## Support Contacts

**Oracle Cloud Support**:
- Free tier: Community forums only
- Paid: 24/7 support

**MCP Gateway Issues**:
- Check logs: `docker logs mcp-gateway`
- Review: `PROJECT_SUMMARY.md` and `README.md` in project dir

---

*Guide created: 2025-11-10*
*Target: Oracle Cloud Infrastructure - Always Free Tier*
*Architecture: ARM64 (Ampere A1)*
