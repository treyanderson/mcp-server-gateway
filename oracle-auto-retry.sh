#!/bin/bash
#
# Oracle Cloud ARM Instance Auto-Retry Script
# Keeps trying until capacity is available
#
# Usage: ./oracle-auto-retry.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# CONFIGURATION - FILL THESE IN
# ============================================

# Get these values from Step 3 above
COMPARTMENT_ID="PASTE_YOUR_COMPARTMENT_OCID_HERE"
AVAILABILITY_DOMAIN="PASTE_YOUR_AD_HERE"  # e.g., xyz:US-ASHBURN-AD-2
IMAGE_ID="PASTE_YOUR_IMAGE_OCID_HERE"
SUBNET_ID="PASTE_YOUR_SUBNET_OCID_HERE"
SSH_PUBLIC_KEY="PASTE_YOUR_SSH_PUBLIC_KEY_HERE"

# Instance configuration
SHAPE="VM.Standard.A1.Flex"
OCPUS=2
MEMORY_GB=12
DISPLAY_NAME="mcp-gateway-prod"

# Retry configuration
RETRY_DELAY=60  # seconds between attempts
MAX_ATTEMPTS=10000  # essentially infinite

# ============================================
# VALIDATION
# ============================================

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Oracle Cloud Instance Auto-Retry${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if values are filled in
if [[ "$COMPARTMENT_ID" == *"PASTE_YOUR"* ]] || \
   [[ "$AVAILABILITY_DOMAIN" == *"PASTE_YOUR"* ]] || \
   [[ "$IMAGE_ID" == *"PASTE_YOUR"* ]] || \
   [[ "$SUBNET_ID" == *"PASTE_YOUR"* ]] || \
   [[ "$SSH_PUBLIC_KEY" == *"PASTE_YOUR"* ]]; then
    echo -e "${RED}ERROR: Please fill in all configuration values in the script!${NC}"
    echo ""
    echo "Edit this script and replace:"
    echo "  - PASTE_YOUR_COMPARTMENT_OCID_HERE"
    echo "  - PASTE_YOUR_AD_HERE"
    echo "  - PASTE_YOUR_IMAGE_OCID_HERE"
    echo "  - PASTE_YOUR_SUBNET_OCID_HERE"
    echo "  - PASTE_YOUR_SSH_PUBLIC_KEY_HERE"
    echo ""
    exit 1
fi

# Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    echo -e "${RED}ERROR: OCI CLI is not installed!${NC}"
    echo "Install with: bash -c \"\$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)\""
    exit 1
fi

# Check if OCI CLI is configured
if [ ! -f "$HOME/.oci/config" ]; then
    echo -e "${RED}ERROR: OCI CLI is not configured!${NC}"
    echo "Run: oci setup config"
    exit 1
fi

echo -e "${GREEN}✓ Configuration validated${NC}"
echo ""
echo "Settings:"
echo "  Compartment: ${COMPARTMENT_ID:0:20}..."
echo "  AD: $AVAILABILITY_DOMAIN"
echo "  Shape: $SHAPE ($OCPUS OCPUs, ${MEMORY_GB}GB RAM)"
echo "  Display name: $DISPLAY_NAME"
echo "  Retry delay: ${RETRY_DELAY}s"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop at any time${NC}"
echo ""

# ============================================
# RETRY LOOP
# ============================================

ATTEMPT=1
START_TIME=$(date +%s)

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))

    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] Attempt #$ATTEMPT (${ELAPSED_MIN} minutes elapsed)${NC}"

    # Attempt to create instance
    RESULT=$(oci compute instance launch \
        --compartment-id "$COMPARTMENT_ID" \
        --availability-domain "$AVAILABILITY_DOMAIN" \
        --shape "$SHAPE" \
        --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORY_GB}" \
        --image-id "$IMAGE_ID" \
        --subnet-id "$SUBNET_ID" \
        --assign-public-ip true \
        --display-name "$DISPLAY_NAME" \
        --metadata "{\"ssh_authorized_keys\": \"$SSH_PUBLIC_KEY\"}" \
        2>&1)

    # Check result
    if echo "$RESULT" | grep -q "OutOfHostCapacity\|OutOfCapacity"; then
        echo -e "${YELLOW}  ⚠ Out of capacity, retrying in ${RETRY_DELAY}s...${NC}"
        sleep $RETRY_DELAY
        ATTEMPT=$((ATTEMPT + 1))

    elif echo "$RESULT" | grep -q '"lifecycle-state": "PROVISIONING"\|"lifecycle-state": "RUNNING"'; then
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}SUCCESS! Instance created! 🎉${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""

        # Extract instance ID
        INSTANCE_ID=$(echo "$RESULT" | grep -o '"id": "[^"]*"' | head -1 | cut -d'"' -f4)
        echo "Instance ID: $INSTANCE_ID"
        echo ""

        # Wait a moment for instance to provision
        echo "Waiting for instance to fully provision..."
        sleep 30

        # Get public IP
        echo "Fetching public IP address..."
        PUBLIC_IP=$(oci compute instance list-vnics \
            --instance-id "$INSTANCE_ID" \
            --query 'data[0]."public-ip"' \
            --raw-output 2>/dev/null || echo "Not available yet")

        if [ "$PUBLIC_IP" != "Not available yet" ] && [ -n "$PUBLIC_IP" ]; then
            echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Wait 1-2 minutes for instance to fully boot"
            echo "2. Test SSH connection:"
            echo -e "   ${YELLOW}ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@$PUBLIC_IP${NC}"
            echo "3. Run deployment script:"
            echo -e "   ${YELLOW}./deploy-to-oracle.sh $PUBLIC_IP${NC}"
        else
            echo "Public IP not available yet. Check Oracle Console:"
            echo "https://cloud.oracle.com/compute/instances"
        fi

        echo ""
        echo "Instance details saved to: oracle-instance-info.txt"
        cat > oracle-instance-info.txt << EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Created: $(date)
SSH Command: ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@$PUBLIC_IP
Deploy Command: ./deploy-to-oracle.sh $PUBLIC_IP
EOF

        exit 0

    elif echo "$RESULT" | grep -q "LimitExceeded"; then
        echo -e "${RED}  ✗ Limit exceeded - check your free tier limits${NC}"
        echo "$RESULT"
        exit 1

    elif echo "$RESULT" | grep -q "InvalidParameter"; then
        echo -e "${RED}  ✗ Invalid parameter - check your configuration${NC}"
        echo "$RESULT"
        exit 1

    elif echo "$RESULT" | grep -q "NotAuthorizedOrNotFound"; then
        echo -e "${RED}  ✗ Authorization error - check your API key and permissions${NC}"
        echo "$RESULT"
        exit 1

    else
        echo -e "${YELLOW}  ⚠ Unexpected response, retrying...${NC}"
        echo "$RESULT" | head -5
        sleep $RETRY_DELAY
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo ""
echo -e "${RED}Failed after $MAX_ATTEMPTS attempts${NC}"
exit 1
