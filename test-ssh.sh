#!/bin/bash
#
# Test SSH connection to Oracle instance
#

ORACLE_IP="150.136.244.110"
SSH_KEY="$HOME/.ssh/oracle-mcp-gateway.key"

echo "Testing SSH connection to Oracle Cloud instance..."
echo "IP: $ORACLE_IP"
echo "Key: $SSH_KEY"
echo ""

# Check if key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "ERROR: SSH key not found at $SSH_KEY"
    exit 1
fi

# Check key permissions
PERMS=$(stat -f "%OLp" "$SSH_KEY" 2>/dev/null || stat -c "%a" "$SSH_KEY" 2>/dev/null)
if [ "$PERMS" != "600" ]; then
    echo "Fixing SSH key permissions..."
    chmod 600 "$SSH_KEY"
fi

# Test connection
echo "Attempting to connect..."
echo ""

ssh -i "$SSH_KEY" \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=no \
    ubuntu@$ORACLE_IP \
    "echo '✓ SSH connection successful!'; echo ''; echo 'Instance details:'; uname -a; echo ''; echo 'Available memory:'; free -h"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "SUCCESS! SSH is working!"
    echo "=========================================="
    echo ""
    echo "Next step: Run the deployment script"
    echo "  ./deploy-to-oracle.sh $ORACLE_IP"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "SSH connection failed"
    echo "=========================================="
    echo ""
    echo "Troubleshooting:"
    echo "1. Check Oracle Security List allows port 22"
    echo "2. Verify you uploaded id_ed25519.pub when creating instance"
    echo "3. Wait 2-3 minutes if instance just started"
    echo ""
fi
