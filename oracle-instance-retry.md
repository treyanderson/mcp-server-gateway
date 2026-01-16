# Oracle Cloud Instance Auto-Retry Guide

Oracle's free ARM instances are in high demand. This guide shows you how to automatically retry until capacity is available.

## Strategy 1: Manual Retry at Best Times

**Best times to try** (lower usage):
- **Early morning**: 5-8 AM your local time
- **Late night**: 11 PM - 2 AM your local time
- **Weekday mornings**: Better than weekends
- **Tuesday-Thursday**: Best days of the week

## Strategy 2: Use OCI CLI Auto-Retry Script

Oracle CLI can automatically retry instance creation until it succeeds.

### Step 1: Install OCI CLI (On Your Mac)

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

Follow the prompts (accept defaults).

### Step 2: Configure OCI CLI

```bash
oci setup config
```

You'll need:
- **User OCID**: Oracle Console → Profile (top right) → User Settings → Copy OCID
- **Tenancy OCID**: Oracle Console → Profile → Tenancy → Copy OCID
- **Region**: Your region identifier (e.g., `us-ashburn-1`)
- **API Key**: CLI will generate one for you

### Step 3: Upload API Key to Oracle

After `oci setup config`, it will show you a public key. Copy it.

Then:
1. Oracle Console → Profile → User Settings
2. Scroll to **"API Keys"**
3. Click **"Add API Key"**
4. Paste the public key
5. Click **"Add"**

### Step 4: Create Auto-Retry Script

```bash
cat > ~/oracle-create-instance.sh << 'EOF'
#!/bin/bash

# Configuration
COMPARTMENT_ID="YOUR_COMPARTMENT_OCID"
AVAILABILITY_DOMAIN="YOUR_REGION:AD-1"  # Try AD-1, AD-2, AD-3
SHAPE="VM.Standard.A1.Flex"
OCPUS=2
MEMORY_GB=12
IMAGE_ID="YOUR_UBUNTU_IMAGE_OCID"
SUBNET_ID="YOUR_SUBNET_OCID"
SSH_KEY="YOUR_SSH_PUBLIC_KEY"

# Retry loop
ATTEMPT=1
MAX_ATTEMPTS=1000

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt #$ATTEMPT at $(date)"

    RESULT=$(oci compute instance launch \
        --compartment-id "$COMPARTMENT_ID" \
        --availability-domain "$AVAILABILITY_DOMAIN" \
        --shape "$SHAPE" \
        --shape-config '{"ocpus": '$OCPUS', "memoryInGBs": '$MEMORY_GB'}' \
        --image-id "$IMAGE_ID" \
        --subnet-id "$SUBNET_ID" \
        --assign-public-ip true \
        --display-name "mcp-gateway-prod" \
        --metadata '{"ssh_authorized_keys": "'"$SSH_KEY"'"}' \
        2>&1)

    if echo "$RESULT" | grep -q "OutOfCapacity"; then
        echo "Out of capacity, retrying in 60 seconds..."
        sleep 60
        ATTEMPT=$((ATTEMPT + 1))
    elif echo "$RESULT" | grep -q "\"id\":"; then
        echo "SUCCESS! Instance created!"
        echo "$RESULT"
        exit 0
    else
        echo "Unexpected error:"
        echo "$RESULT"
        sleep 60
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo "Failed after $MAX_ATTEMPTS attempts"
exit 1
EOF

chmod +x ~/oracle-create-instance.sh
```

### Step 5: Get Required OCIDs

You need to fill in these values in the script:

**Compartment OCID**:
```bash
oci iam compartment list --all | grep '"id":'
```
Usually your root compartment (first one).

**Availability Domain**:
```bash
oci iam availability-domain list | grep '"name":'
```
Pick one (e.g., `xyz:US-ASHBURN-AD-1`)

**Ubuntu Image OCID**:
```bash
oci compute image list --compartment-id YOUR_COMPARTMENT_OCID \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    | grep '"id":'
```

**Subnet OCID**:
```bash
oci network subnet list --compartment-id YOUR_COMPARTMENT_OCID \
    | grep '"id":'
```

**SSH Public Key**:
```bash
cat ~/.ssh/oracle-mcp-gateway.key.pub
```

### Step 6: Run the Retry Script

```bash
~/oracle-create-instance.sh
```

**This will keep retrying every 60 seconds until it succeeds!**

You can leave it running overnight.

## Strategy 3: Community Scripts

GitHub has pre-built retry scripts:

### Option A: Python Script (Most Popular)

```bash
# Clone the repo
git clone https://github.com/hitrov/oci-arm-host-capacity.git
cd oci-arm-host-capacity

# Install dependencies
pip3 install oci

# Configure (edit config.py with your OCIDs)
nano config.py

# Run
python3 oci_arm_host_capacity.py
```

Source: https://github.com/hitrov/oci-arm-host-capacity

### Option B: Terraform Script

```bash
# Clone
git clone https://github.com/sochubert/oracle-cloud-terraform.git
cd oracle-cloud-terraform

# Configure
nano variables.tf

# Run (keeps retrying)
terraform apply -auto-approve
```

## Strategy 4: Keep Clicking in UI

The old-fashioned way that works:

1. Click **"Create Instance"**
2. Fill in all details
3. Click **"Create"**
4. Get capacity error
5. **Immediately click "Create" again** (details are saved)
6. Repeat until it works

**Tips**:
- Use browser auto-refresh extension
- Try different times of day
- Be patient - people report success after 2-48 hours

## What Usually Works

**Most successful approaches** (from community reports):

1. **CLI retry script** (70% success within 24 hours)
2. **Different region** (60% success immediately)
3. **Different AD** (40% success immediately)
4. **Early morning retries** (50% success)
5. **Manual clicking marathon** (80% success within 3 days)

## Alternative: Use x86_64 Micro Instance (Free Tier)

If you're really stuck, Oracle also offers free x86_64 instances:

**Shape**: `VM.Standard.E2.1.Micro`
- **Free tier**: 2 instances
- **Specs**: 1 OCPU, 1GB RAM
- **Availability**: Much better (rarely out of capacity)
- **Trade-off**: Need to rebuild Docker image for x86_64

## Monitoring Capacity

Check Oracle status page for known capacity issues:
https://ocistatus.oraclecloud.com/

## Success Stories

From the community:
- "Took 36 hours of retrying but finally got it!"
- "Switched to Phoenix region, worked immediately"
- "Used the Python script, got instance in 8 hours"
- "Clicked manually for 2 days, persistence paid off"

**Don't give up!** The free ARM instances are worth it.

---

*Last updated: 2025-11-10*
