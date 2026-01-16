# Next Steps After Oracle Instance Creation

Your instance is running! Here's what to do next.

## Instance Information

**From your screenshot**:
- Public IP: `150.136.244.110`
- Username: `ubuntu`
- Shape: VM.Standard.E2.1.Micro (x86_64)
- Status: Running ✅

---

## Step 1: Configure Security List (Allow SSH)

### In Oracle Console (where you are now):

1. **Click the "Networking" tab** (top of the page, next to "Details")

2. Under **"Primary VNIC"**, you'll see:
   - Subnet: Click on the subnet name (e.g., "subnet-..." link)

3. This opens the Subnet page. Look for **"Security Lists"** section

4. Click on the Security List name (e.g., "Default Security List for leap21")

5. Look at **"Ingress Rules"** section
   - Check if there's a rule for **Port 22** (SSH)

6. **If Port 22 rule exists**: Skip to Step 2 ✅

7. **If Port 22 rule is missing**: Click **"Add Ingress Rules"** and fill in:
   ```
   Source CIDR: 0.0.0.0/0
   IP Protocol: TCP
   Destination Port Range: 22
   Description: SSH access
   ```
   Then click **"Add Ingress Rules"**

---

## Step 2: Test SSH Connection (2 minutes)

### On your Mac, open Terminal and run:

```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.136.244.110
```

### Possible outcomes:

**A) Success** - You see `ubuntu@map-gateway-prod:~$`
- ✅ Great! Continue to Step 3

**B) "Connection timed out"**
- ❌ Security List doesn't allow SSH yet
- Go back to Step 1 and add the port 22 rule
- Wait 1-2 minutes after adding the rule

**C) "Permission denied (publickey)"**
- ❌ Wrong SSH key
- Did Oracle give you a different key when you created the instance?
- Check your Downloads folder for `ssh-key-*.key`

**D) "Host key verification failed"**
- Just type `yes` and press Enter

**E) SSH key permissions error**
- Run: `chmod 600 ~/.ssh/oracle-mcp-gateway.key`
- Try SSH again

---

## Step 3: Run Deployment Script (10 minutes)

Once SSH works, **on your Mac**:

```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway

# Run the automated deployment
./deploy-to-oracle.sh 150.136.244.110
```

### What the script does:

1. ✅ Exports Docker image from your Mac
2. ✅ Exports data volume from your Mac
3. ✅ Transfers everything to Oracle Cloud
4. ✅ Loads image on Oracle Cloud
5. ✅ **Rebuilds for x86_64** (you have x86_64, not ARM64)
6. ✅ Restores data
7. ✅ Starts container
8. ✅ Verifies deployment

**The rebuild step is automatic** - the script detects architecture mismatch and rebuilds.

---

## Troubleshooting

### Issue: Can't find SSH key

If you don't have `~/.ssh/oracle-mcp-gateway.key`:

1. Check Downloads folder: `ls ~/Downloads/ssh-key-*.key`
2. If found, move it:
   ```bash
   mv ~/Downloads/ssh-key-*.key ~/.ssh/oracle-mcp-gateway.key
   chmod 600 ~/.ssh/oracle-mcp-gateway.key
   ```
3. Try SSH again

### Issue: Deployment script fails

Common causes:
- **Out of disk space on Mac**: Check `/tmp` has space
- **Docker not running**: Start Docker Desktop
- **Network interrupted**: Re-run the script, it resumes

### Issue: Container won't start on Oracle

After deployment, if container fails:

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.136.244.110

# Check logs
docker logs mcp-gateway

# Common issue: Memory (only 1GB on Micro instance)
# Solution: Reduce container memory if needed
```

---

## After Successful Deployment

Once deployment completes:

1. **Verify container is running**:
   ```bash
   ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.136.244.110
   docker ps
   docker logs mcp-gateway
   ```

2. **Set up firewall** (security):
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw enable
   ```

3. **Stop Mac container**:
   ```bash
   cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
   docker compose down
   ```

4. **Update Claude Desktop** to point to Oracle instance

5. **Set up backups** (optional):
   See ORACLE_CLOUD_SETUP.md Part 9

---

## Quick Commands Reference

```bash
# SSH into instance
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.136.244.110

# Check container status
docker ps

# View logs
docker logs -f mcp-gateway

# Restart container
docker restart mcp-gateway

# Check system resources
free -h
df -h
```

---

## Important Notes

### x86_64 vs ARM64

You got an **x86_64 Micro** instance (not ARM64 A1.Flex).

**Good news**:
- ✅ Always available (no capacity issues)
- ✅ Free tier
- ✅ Deployment script handles rebuild automatically

**Trade-offs**:
- ⚠️ Less RAM (1GB vs 12GB on ARM)
- ⚠️ Less CPU (1 OCPU vs 2-4 on ARM)
- ✅ Should still work fine for MCP Gateway

### Memory Considerations

With only 1GB RAM, monitor memory usage:

```bash
# After deployment
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@150.136.244.110
free -h
docker stats mcp-gateway --no-stream
```

If memory is tight, you can:
- Keep only essential MCP servers enabled
- Disable unused servers in config.json

---

## Success Checklist

- [ ] Security List allows port 22
- [ ] SSH connection works
- [ ] Deployment script completed
- [ ] Container is running
- [ ] Logs show no errors
- [ ] Firewall configured
- [ ] Mac container stopped
- [ ] Claude Desktop updated

---

*Created: 2025-11-10*
*Instance: map-gateway-prod*
*IP: 150.136.244.110*
