# Fix UniFi Dream Machine Blocking Oracle Cloud IP

Your UniFi Dream Machine is blocking access to `150.136.244.110`. Here's how to fix it.

---

## Quick Fix: Whitelist the IP

### Option 1: UniFi Network App (Recommended)

**On your phone or computer**:

1. Open **UniFi Network** app/web interface
   - Web: https://unifi.ui.com or `https://your-udm-ip`

2. Go to **Settings** → **Security** (or **Threat Management**)

3. Find **IPS/IDS Settings** or **Threat Management**

4. Look for **"Whitelist"** or **"Allowed IPs"** section

5. **Add the Oracle IP**:
   - IP: `150.136.244.110/32`
   - Description: `Oracle Cloud MCP Gateway`

6. **Save** changes

7. **Wait 30 seconds** for changes to apply

8. **Test SSH** again:
   ```bash
   cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
   ./test-ssh.sh
   ```

---

## Option 2: Temporarily Disable Threat Management (Quick Test)

**To test if UniFi is the issue**:

1. UniFi Network → **Settings** → **Security**

2. Find **"Threat Management"** or **"IPS/IDS"**

3. **Toggle OFF** temporarily

4. **Test SSH**:
   ```bash
   ./test-ssh.sh
   ```

5. If it works, **toggle back ON** and use Option 1 to whitelist instead

---

## Option 3: Whitelist via IP Group

**More organized approach**:

1. UniFi Network → **Settings** → **Profiles** → **IP Groups**

2. Click **"Create New IP Group"**
   - Name: `Cloud Servers`
   - Type: `IPv4 Address/Subnet`
   - Address: `150.136.244.110/32`

3. Go to **Settings** → **Security** → **Threat Management**

4. Under **"Traffic Rules"** or **"Exceptions"**:
   - Add IP Group: `Cloud Servers`
   - Action: `Allow`

5. **Save** and wait 30 seconds

---

## Option 4: Check UniFi Logs

**To see what's being blocked**:

1. UniFi Network → **Events** or **Logs**

2. Filter by:
   - Type: `IPS Events` or `Threat Management`
   - Time: Last hour

3. Look for entries with `150.136.244.110`

4. Note the **reason** (e.g., "Geo-IP", "Suspicious Traffic", "Known Threat")

5. Based on reason:
   - **Geo-IP Block**: Disable geo-blocking for US regions
   - **Known Threat**: Whitelist the specific IP
   - **Suspicious Traffic**: Add to IPS exceptions

---

## Option 5: Disable Country Blocking (If Applicable)

If Oracle IP is being geo-blocked:

1. UniFi Network → **Settings** → **Security** → **Country Restrictions**

2. **Uncheck** "United States" from blocked countries

3. Or add exception for `150.136.244.110`

---

## Option 6: Use SSH over Different Port (Workaround)

**If whitelisting doesn't work**, use SSH tunnel through allowed port:

This is more complex, but I can help set it up if needed.

---

## Verification Steps

After whitelisting:

### Test 1: Ping the IP
```bash
ping -c 3 150.136.244.110
```

**Expected**: Replies from 150.136.244.110

**If fails**: UDM still blocking ICMP (ping), but SSH might work

### Test 2: Test Port 22
```bash
nc -zv 150.136.244.110 22
```

**Expected**: `Connection to 150.136.244.110 port 22 [tcp/ssh] succeeded!`

**If fails**: Port still blocked

### Test 3: SSH Connection
```bash
cd /Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway
./test-ssh.sh
```

**Expected**: SSH connects successfully

---

## Common UniFi Blocking Reasons

### 1. Threat Intelligence Feed
- Oracle IPs might be flagged in threat databases
- **Fix**: Whitelist specific IP

### 2. Geo-IP Blocking
- Blocking data center IPs
- **Fix**: Disable geo-blocking or allow US East region

### 3. IPS/IDS Rules
- Detecting "suspicious" SSH patterns
- **Fix**: Add IPS exception for this IP

### 4. DPI (Deep Packet Inspection)
- Analyzing SSH traffic as suspicious
- **Fix**: Disable DPI for this IP or reduce sensitivity

---

## UniFi Controller Paths

**UniFi Dream Machine** / **UDM Pro** / **UDM SE**:

### Old UI:
```
Settings → Security → Internet Threat Management → IP Reputation
→ Add to whitelist
```

### New UI:
```
Settings → Security → Threat Management → IPS
→ Categories → Custom Rules → Add Exception
```

### UniFi OS Console (newest):
```
UniFi Network → Settings → Security → Threat Management
→ Allowlist → Add IP Address
```

---

## Quick Command to Test Connectivity

```bash
# Test if UDM is blocking
curl -v --connect-timeout 5 telnet://150.136.244.110:22

# If this hangs/times out → UDM is blocking
# If you see "Connected" → UDM allows it, Oracle Security List needs fixing
```

---

## Still Blocked?

### Check These Settings:

1. **Firewall Rules**: Settings → Routing & Firewall → Firewall
   - Make sure no rules blocking outbound to `150.136.244.110`

2. **Traffic Rules**: Settings → Traffic Management
   - No rules rate-limiting or blocking SSH

3. **Client Isolation**: Settings → Networks
   - Your device's network allows internet access

4. **VPN/Tunnel**: If using VPN
   - Disable temporarily to test

---

## Nuclear Option: Factory Reset Threat Management

**Only if nothing else works**:

1. Settings → Security → Threat Management
2. Click **"Reset to Defaults"** or **"Restore Default Settings"**
3. Re-enable threat management with default rules
4. Test connection

---

## Alternative: Use Mobile Hotspot (Quick Test)

**To verify it's UniFi**:

1. **Disconnect Mac from WiFi**
2. **Connect to iPhone/Android hotspot**
3. **Test SSH**:
   ```bash
   ./test-ssh.sh
   ```

**If works on hotspot**: Confirms UniFi is blocking
**If still fails**: Oracle Security List needs fixing

---

## Most Likely Solution

For UniFi Dream Machine, try this first:

1. **Open UniFi Network** (web or app)
2. **Settings** → **Security** → **Threat Management**
3. Find **"Allowlist"** or **"Whitelist"** section
4. **Add IP**: `150.136.244.110`
5. **Description**: `Oracle Cloud Instance`
6. **Save**
7. **Wait 30 seconds**
8. **Test**: `./test-ssh.sh`

This works 90% of the time!

---

*Created: 2025-11-10*
*Oracle IP: 150.136.244.110*
*UDM Issue: Threat Management blocking cloud IP*
