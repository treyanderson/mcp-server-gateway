# Oracle Cloud Networking Setup - Step-by-Step Guide

**Complete guide to configuring Oracle Cloud networking for MCP Gateway**

Oracle Cloud has **TWO layers of firewalls** - this guide covers both!

---

## Understanding Oracle Cloud Networking

### Two Firewall Layers

```
Internet
    ↓
[OCI Security List] ← Cloud-level firewall (Oracle controls)
    ↓
[Instance OS Firewall] ← Server-level firewall (Ubuntu UFW)
    ↓
Your MCP Gateway Container
```

**Both must allow traffic!** If either blocks, connection fails.

---

## Part 1: During Instance Creation

### When You Reach "Networking" Section

You'll see a section called **"Networking"** with these fields:

#### 1. Virtual Cloud Network (VCN)

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Virtual cloud network                            │
│ ┌─────────────────────────────────────────────┐ │
│ │ vcn-YYYYMMDD-HHMM (default)            ▼   │ │
│ └─────────────────────────────────────────────┘ │
│                                                   │
│ [Create new virtual cloud network]               │
└─────────────────────────────────────────────────┘
```

**What to do**:
- ✅ **Keep the default** (pre-selected)
- Or if nothing selected: Click dropdown → Select the VCN that exists
- Or if no VCN exists: Check **"Create new virtual cloud network"**

**Why**: VCN is like your private network in the cloud. Oracle auto-creates one for you.

---

#### 2. Subnet

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Subnet                                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ subnet-YYYYMMDD-HHMM (regional)        ▼   │ │
│ └─────────────────────────────────────────────┘ │
│                                                   │
│ [Create new subnet]                              │
└─────────────────────────────────────────────────┘
```

**What to do**:
- ✅ **Select "Public Subnet"** (should say "regional" or "public")
- ❌ **NOT "Private Subnet"** (won't be able to SSH in)

**Look for**: The word **"Public"** in the subnet name

---

#### 3. Public IP Address (CRITICAL!)

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ ☐ Assign a public IPv4 address                  │
│                                                   │
│ ☐ Assign a public IPv6 address                  │
└─────────────────────────────────────────────────┘
```

**What to do**:
- ✅ **CHECK** "Assign a public IPv4 address" ← MUST be checked!
- ⚠️ If unchecked, you won't be able to connect!

**Why**: Without public IP, you can't SSH into the instance from your Mac.

---

#### 4. Network Security Group (Optional)

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Network security group                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ (None selected)                         ▼   │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**What to do**:
- ✅ **Leave as "(None)"** for now
- We'll use Security Lists instead (simpler)

---

### Summary: Networking During Creation

**Checklist**:
- [ ] VCN: Default selected (or create new)
- [ ] Subnet: **Public subnet** selected
- [ ] **☑ Assign a public IPv4 address** ← CHECKED!
- [ ] Network Security Group: None

**Then click**: **"Create"** at the bottom of the page

---

## Part 2: Configure Security List (AFTER Instance Created)

### Wait for Instance to Be Running

1. Instance will show **"PROVISIONING"** (orange) for 2-3 minutes
2. Wait until it shows **"RUNNING"** (green)
3. Click on the instance name to see details

---

### Find Your Security List

**Step 1**: In instance details, scroll down to **"Primary VNIC"** section

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Primary VNIC                                     │
├─────────────────────────────────────────────────┤
│ VNIC name: vnic-YYYYMMDD-HHMM                   │
│ Private IP address: 10.0.0.123                  │
│ Public IP address: 150.230.45.123 ← YOUR IP!    │
│ Subnet: subnet-YYYYMMDD-HHMM                    │
│ Network security groups: -                       │
└─────────────────────────────────────────────────┘
```

**Step 2**: Click on the **Subnet** link (e.g., "subnet-YYYYMMDD-HHMM")

---

**Step 3**: You'll see subnet details page

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Subnet Information                               │
├─────────────────────────────────────────────────┤
│ Name: subnet-YYYYMMDD-HHMM                      │
│ CIDR Block: 10.0.0.0/24                         │
│ Route Table: Default Route Table...             │
│ Security Lists: Default Security List...  ←     │
└─────────────────────────────────────────────────┘
```

**Step 4**: Under **"Security Lists"**, click on the security list name

Usually named: **"Default Security List for vcn-YYYYMMDD-HHMM"**

---

### View Current Rules

**What you'll see**:
```
┌─────────────────────────────────────────────────┐
│ Ingress Rules                                    │
├──────┬─────────┬──────────┬──────────┬─────────┤
│ Port │ Source  │ Protocol │ Type     │ Actions │
├──────┼─────────┼──────────┼──────────┼─────────┤
│ 22   │0.0.0.0/0│   TCP    │          │ [Edit]  │
└──────┴─────────┴──────────┴──────────┴─────────┘
```

**Look for**:
- Port **22** (SSH) should already exist
- Source: `0.0.0.0/0` (means "from anywhere")

**If port 22 rule exists**: You're good! Skip to "Optional: Restrict SSH Access"

**If port 22 rule MISSING**: Continue to next section

---

### Add SSH Rule (If Missing)

**Step 1**: Click **"Add Ingress Rules"** button (top of page)

**Step 2**: Fill in the form:

```
┌─────────────────────────────────────────────────┐
│ Add Ingress Rule                                 │
├─────────────────────────────────────────────────┤
│ Stateless:                                       │
│   ☐ Stateless                                   │
│                                                   │
│ Source Type:                                     │
│   ◉ CIDR  ○ Service                             │
│                                                   │
│ Source CIDR:                                     │
│   ┌─────────────────────────────────────────┐  │
│   │ 0.0.0.0/0                                │  │
│   └─────────────────────────────────────────┘  │
│                                                   │
│ IP Protocol:                                     │
│   ┌─────────────────────────────────────────┐  │
│   │ TCP                                 ▼   │  │
│   └─────────────────────────────────────────┘  │
│                                                   │
│ Source Port Range:                               │
│   ┌─────────────────────────────────────────┐  │
│   │ (leave empty)                            │  │
│   └─────────────────────────────────────────┘  │
│                                                   │
│ Destination Port Range:                          │
│   ┌─────────────────────────────────────────┐  │
│   │ 22                                       │  │
│   └─────────────────────────────────────────┘  │
│                                                   │
│ Description:                                     │
│   ┌─────────────────────────────────────────┐  │
│   │ SSH access                               │  │
│   └─────────────────────────────────────────┘  │
│                                                   │
│         [Cancel]  [Add Ingress Rules]            │
└─────────────────────────────────────────────────┘
```

**Fill in**:
1. **Stateless**: Leave unchecked
2. **Source Type**: Select **"CIDR"**
3. **Source CIDR**: Enter `0.0.0.0/0` (allows from anywhere)
4. **IP Protocol**: Select **"TCP"**
5. **Source Port Range**: Leave empty
6. **Destination Port Range**: Enter `22`
7. **Description**: Enter `SSH access`

**Step 3**: Click **"Add Ingress Rules"** button at bottom

---

### Optional: Restrict SSH Access (Recommended for Security)

Instead of allowing SSH from anywhere (`0.0.0.0/0`), restrict to YOUR IP only.

**Step 1**: Find your public IP
```bash
# On your Mac
curl ifconfig.me
```

Example output: `203.0.113.45`

**Step 2**: Edit the SSH rule

In Security List, click **"Edit"** on the port 22 rule

**Step 3**: Change Source CIDR
```
From: 0.0.0.0/0
To:   203.0.113.45/32  ← Your IP + /32
```

**Why `/32`?** This means "only this exact IP address"

**Step 4**: Click **"Save Changes"**

**Warning**: If your home IP changes (dynamic IP), you'll lose access. Only do this if you have static IP or are willing to update it.

---

### Optional: Add Custom Port (If MCP Gateway Needs HTTP Access)

**Most MCP Gateways use stdio (no external port needed)**, but if yours exposes HTTP:

**Step 1**: Click **"Add Ingress Rules"**

**Step 2**: Fill in:
- **Source CIDR**: `0.0.0.0/0` (or your IP for security)
- **IP Protocol**: `TCP`
- **Destination Port Range**: `3000` (or your gateway's port)
- **Description**: `MCP Gateway HTTP`

**Step 3**: Click **"Add Ingress Rules"**

---

## Part 3: Configure OS-Level Firewall (After SSH In)

### SSH Into Your Instance

```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_PUBLIC_IP
```

Replace `YOUR_PUBLIC_IP` with the IP from instance details.

---

### Check Current Firewall Status

```bash
sudo iptables -L -n
```

**What you'll see**: Lots of rules (Oracle pre-configures iptables)

**Don't worry about understanding it** - we'll use UFW (simpler)

---

### Install and Configure UFW

**Step 1**: Install UFW (if not installed)
```bash
sudo apt update
sudo apt install ufw -y
```

**Step 2**: Set default policies
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

**Step 3**: Allow SSH (CRITICAL - don't lock yourself out!)
```bash
sudo ufw allow 22/tcp
```

**Optional**: If you restricted SSH to your IP in Security List:
```bash
sudo ufw allow from YOUR_IP to any port 22
```

**Step 4**: Allow custom ports (if needed)
```bash
# Only if MCP Gateway exposes HTTP
sudo ufw allow 3000/tcp
```

**Step 5**: Enable firewall
```bash
sudo ufw enable
```

**You'll see**: `Command may disrupt existing ssh connections. Proceed with operation (y|n)?`

**Type**: `y` and press Enter

**Step 6**: Verify status
```bash
sudo ufw status
```

**Expected output**:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
```

---

## Part 4: Verify Networking Works

### Test SSH Connection

**From your Mac** (new terminal window):
```bash
ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_PUBLIC_IP
```

**Expected**: Should connect successfully

**If fails**: Check both Security List and UFW allow port 22

---

### Test Port Scanning (External View)

**From your Mac**:
```bash
nmap -Pn YOUR_PUBLIC_IP
```

**Expected output**:
```
Starting Nmap...
PORT   STATE SERVICE
22/tcp open  ssh
```

**Good signs**:
- ✅ Port 22 shows as "open"
- ✅ No other ports shown (secure!)

**Bad signs**:
- ❌ Port 22 shows as "filtered" → Security List blocks it
- ❌ Port 22 shows as "closed" → UFW blocks it

---

### Test from Inside Instance

**SSH into instance**, then:
```bash
# Test outbound connectivity (should work)
ping -c 3 google.com

# Check what ports are listening
sudo netstat -tuln | grep LISTEN

# Check UFW status
sudo ufw status numbered
```

---

## Troubleshooting

### Problem: Can't SSH In

**Error**: `Connection timed out` or `No route to host`

**Check these (in order)**:

1. **Instance is running?**
   - Oracle Console → Compute → Instances
   - Status should be "RUNNING" (green)

2. **Public IP assigned?**
   - In instance details, check "Public IP address" field
   - If blank, you need to assign one

3. **Security List allows port 22?**
   - Go to Security List → Ingress Rules
   - Should have: Source 0.0.0.0/0, TCP, Port 22

4. **Subnet is PUBLIC?**
   - Instance details → Primary VNIC → Subnet
   - Should say "public" or "Public Subnet"

5. **SSH key correct?**
   ```bash
   # Check key permissions
   ls -la ~/.ssh/oracle-mcp-gateway.key
   # Should show: -rw------- (600)

   # Fix if wrong
   chmod 600 ~/.ssh/oracle-mcp-gateway.key
   ```

6. **Using correct username?**
   - For Ubuntu: `ubuntu@IP`
   - For Oracle Linux: `opc@IP`

---

### Problem: Connection Refused

**Error**: `Connection refused`

**Means**: Security List allows traffic, but OS firewall blocks it

**Fix**:
```bash
# If you can't SSH, use Oracle Console Connection
# Console → Compute → Instances → Your Instance → Console Connection

# Then check UFW
sudo ufw status

# Allow SSH
sudo ufw allow 22/tcp
```

---

### Problem: Lost SSH Access After Enabling UFW

**Don't panic!** You can still access via Oracle Console Connection.

**Step 1**: Oracle Console → Compute → Instances → Your Instance

**Step 2**: Scroll down to **"Console Connection"**

**Step 3**: Click **"Create Console Connection"**

**Step 4**: Upload your SSH public key

**Step 5**: Wait for connection to be active

**Step 6**: Click **"Launch Cloud Shell Connection"**

**Step 7**: You're in! Now fix UFW:
```bash
sudo ufw allow 22/tcp
sudo ufw reload
```

---

### Problem: Security List Changes Don't Take Effect

**Solutions**:

1. **Wait 1-2 minutes** - changes aren't instant

2. **Check you edited the RIGHT Security List**
   - Your instance might use multiple security lists
   - Go to: Instance → Primary VNIC → Subnet → All attached security lists

3. **Verify rule is correct**
   - Source: 0.0.0.0/0
   - Protocol: TCP
   - Destination Port: 22

4. **Try rebooting instance**
   ```bash
   sudo reboot
   ```

---

## Quick Reference: Networking Checklist

### During Instance Creation
- [ ] VCN: Default or create new
- [ ] Subnet: **Public subnet** selected
- [ ] **☑ Assign a public IPv4 address** ← CRITICAL!
- [ ] Network Security Group: None

### After Instance Created
- [ ] Navigate to Security List (via Subnet)
- [ ] Add ingress rule: Port 22, TCP, Source 0.0.0.0/0
- [ ] (Optional) Restrict SSH to your IP
- [ ] (Optional) Add custom ports if needed

### After SSH In
- [ ] Install UFW: `sudo apt install ufw`
- [ ] Allow SSH: `sudo ufw allow 22/tcp`
- [ ] (Optional) Allow custom ports
- [ ] Enable UFW: `sudo ufw enable`
- [ ] Verify: `sudo ufw status`

### Verification
- [ ] SSH works from Mac
- [ ] Port scan shows only port 22
- [ ] Outbound connectivity works

---

## Visual Summary: Networking Flow

```
┌─────────────────────────────────────────────────┐
│ Your Mac (203.0.113.45)                         │
└───────────────┬─────────────────────────────────┘
                │
                │ SSH to 150.230.45.123:22
                ↓
┌─────────────────────────────────────────────────┐
│ Internet                                         │
└───────────────┬─────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────┐
│ Oracle Cloud Security List (Layer 1)            │
│ ✓ Allow: TCP Port 22 from 0.0.0.0/0            │
└───────────────┬─────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────┐
│ Instance Public IP: 150.230.45.123              │
└───────────────┬─────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────┐
│ Ubuntu UFW Firewall (Layer 2)                   │
│ ✓ Allow: TCP Port 22                            │
└───────────────┬─────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────┐
│ SSH Service (Port 22)                            │
│ ✓ Accepts connection                             │
└─────────────────────────────────────────────────┘
```

**Both layers must allow traffic!**

---

## Next Steps After Networking Is Configured

Once networking is working:

1. ✅ **Test SSH access**: `ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@YOUR_IP`
2. ✅ **Run deployment script**: `./deploy-to-oracle.sh YOUR_IP`
3. ✅ **Configure additional security**: See ORACLE_SECURITY_CHECKLIST.md

---

*Networking guide created: 2025-11-10*
*Last updated: 2025-11-10*
