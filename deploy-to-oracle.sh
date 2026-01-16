#!/bin/bash
#
# deploy-to-oracle.sh - Automated MCP Gateway deployment to Oracle Cloud
#
# Usage: ./deploy-to-oracle.sh [oracle_ip_address]
# Example: ./deploy-to-oracle.sh 150.230.45.123
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/Users/trey/Library/CloudStorage/Dropbox/dev/Github/mcp-server-gateway"
SSH_KEY="$HOME/.ssh/oracle-mcp-gateway.key"
SSH_USER="ubuntu"
REMOTE_DIR="mcp-gateway"

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_header "Checking Requirements"

    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker is running"

    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory not found: $PROJECT_DIR"
        exit 1
    fi
    print_success "Project directory found"

    # Check if SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        print_warning "SSH key not found at: $SSH_KEY"
        print_info "Please ensure you have your Oracle Cloud SSH key at this location"
        print_info "Or update the SSH_KEY variable in this script"
        exit 1
    fi
    print_success "SSH key found"

    # Check SSH key permissions
    KEY_PERMS=$(stat -f "%OLp" "$SSH_KEY" 2>/dev/null || stat -c "%a" "$SSH_KEY")
    if [ "$KEY_PERMS" != "600" ]; then
        print_warning "SSH key has incorrect permissions: $KEY_PERMS"
        print_info "Fixing permissions..."
        chmod 600 "$SSH_KEY"
        print_success "SSH key permissions fixed"
    fi

    echo ""
}

get_oracle_ip() {
    if [ -z "$1" ]; then
        print_info "Enter your Oracle Cloud instance public IP address:"
        read -r ORACLE_IP
    else
        ORACLE_IP="$1"
    fi

    if [ -z "$ORACLE_IP" ]; then
        print_error "No IP address provided"
        exit 1
    fi

    print_success "Using Oracle Cloud IP: $ORACLE_IP"
    echo ""
}

test_ssh_connection() {
    print_header "Testing SSH Connection"

    print_info "Attempting to connect to $SSH_USER@$ORACLE_IP..."

    if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "$SSH_USER@$ORACLE_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection successful"
    else
        print_error "Cannot connect to Oracle Cloud instance"
        print_info "Please verify:"
        print_info "  1. Instance is running (check Oracle Cloud Console)"
        print_info "  2. Security List allows SSH on port 22"
        print_info "  3. IP address is correct: $ORACLE_IP"
        print_info "  4. SSH key is correct: $SSH_KEY"
        exit 1
    fi

    echo ""
}

export_docker_image() {
    print_header "Exporting Docker Image"

    cd "$PROJECT_DIR"

    print_info "Saving Docker image mcp-gateway:latest..."
    docker save mcp-gateway:latest | gzip > /tmp/mcp-gateway-image.tar.gz

    IMAGE_SIZE=$(du -h /tmp/mcp-gateway-image.tar.gz | cut -f1)
    print_success "Docker image exported: $IMAGE_SIZE"

    echo ""
}

export_data_volume() {
    print_header "Exporting Data Volume"

    print_info "Backing up volume: mcp-server-gateway_gateway-data..."
    docker run --rm \
        -v mcp-server-gateway_gateway-data:/data \
        -v /tmp:/backup \
        alpine tar -czf /backup/mcp-gateway-data.tar.gz /data 2>/dev/null

    DATA_SIZE=$(du -h /tmp/mcp-gateway-data.tar.gz | cut -f1)
    print_success "Data volume exported: $DATA_SIZE"

    echo ""
}

export_project_files() {
    print_header "Exporting Project Files"

    cd "$PROJECT_DIR"

    print_info "Creating project archive..."
    tar -czf /tmp/mcp-gateway-project.tar.gz \
        docker-compose.yml \
        Dockerfile \
        config.json \
        .env \
        package.json \
        package-lock.json \
        tsconfig.json \
        src/ \
        dist/ 2>/dev/null || true

    PROJECT_SIZE=$(du -h /tmp/mcp-gateway-project.tar.gz | cut -f1)
    print_success "Project files exported: $PROJECT_SIZE"

    echo ""
}

transfer_files() {
    print_header "Transferring Files to Oracle Cloud"

    TOTAL_SIZE=$(du -h /tmp/mcp-gateway-*.tar.gz | awk '{sum+=$1} END {print sum}')
    print_info "Total size to transfer: ~$TOTAL_SIZE MB"
    print_info "This may take 5-15 minutes depending on your upload speed..."
    echo ""

    # Transfer Docker image
    print_info "Transferring Docker image..."
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        /tmp/mcp-gateway-image.tar.gz \
        "$SSH_USER@$ORACLE_IP:/tmp/" || {
        print_error "Failed to transfer Docker image"
        exit 1
    }
    print_success "Docker image transferred"

    # Transfer data volume
    print_info "Transferring data volume..."
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        /tmp/mcp-gateway-data.tar.gz \
        "$SSH_USER@$ORACLE_IP:/tmp/" || {
        print_error "Failed to transfer data volume"
        exit 1
    }
    print_success "Data volume transferred"

    # Transfer project files
    print_info "Transferring project files..."
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        /tmp/mcp-gateway-project.tar.gz \
        "$SSH_USER@$ORACLE_IP:/tmp/" || {
        print_error "Failed to transfer project files"
        exit 1
    }
    print_success "Project files transferred"

    echo ""
}

deploy_on_oracle() {
    print_header "Deploying on Oracle Cloud"

    print_info "Executing remote deployment script..."

    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$ORACLE_IP" << 'REMOTE_SCRIPT'
        set -e

        echo "→ Creating project directory..."
        mkdir -p ~/mcp-gateway
        cd ~/mcp-gateway

        echo "→ Extracting project files..."
        tar -xzf /tmp/mcp-gateway-project.tar.gz

        echo "→ Loading Docker image..."
        docker load -i /tmp/mcp-gateway-image.tar.gz

        echo "→ Creating data volume..."
        docker volume create mcp-server-gateway_gateway-data || true

        echo "→ Restoring data..."
        docker run --rm \
            -v mcp-server-gateway_gateway-data:/data \
            -v /tmp:/backup \
            alpine sh -c "cd / && tar -xzf /backup/mcp-gateway-data.tar.gz"

        echo "→ Starting MCP Gateway..."
        docker compose up -d

        echo "→ Waiting for container to start..."
        sleep 5

        echo "→ Checking container status..."
        docker ps | grep mcp-gateway

        echo ""
        echo "✓ Deployment complete!"
        echo ""
        echo "Container logs:"
        docker logs --tail 20 mcp-gateway
REMOTE_SCRIPT

    print_success "Deployment successful!"

    echo ""
}

verify_deployment() {
    print_header "Verifying Deployment"

    print_info "Checking container status..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$ORACLE_IP" \
        "docker ps --filter name=mcp-gateway --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

    echo ""
    print_info "Recent logs:"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$ORACLE_IP" \
        "docker logs --tail 30 mcp-gateway"

    echo ""
}

cleanup_local() {
    print_header "Cleanup"

    print_info "Do you want to remove exported files from /tmp? (y/n)"
    read -r CLEANUP

    if [ "$CLEANUP" = "y" ] || [ "$CLEANUP" = "Y" ]; then
        rm -f /tmp/mcp-gateway-*.tar.gz
        print_success "Local temporary files removed"
    else
        print_info "Temporary files kept at: /tmp/mcp-gateway-*.tar.gz"
    fi

    echo ""
}

display_next_steps() {
    print_header "Deployment Complete! 🎉"

    echo -e "${GREEN}Your MCP Gateway is now running on Oracle Cloud!${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Verify all MCP servers are connected:"
    echo -e "   ${YELLOW}ssh -i $SSH_KEY $SSH_USER@$ORACLE_IP${NC}"
    echo -e "   ${YELLOW}docker logs -f mcp-gateway${NC}"
    echo ""
    echo "2. Update Claude Desktop configuration to point to:"
    echo -e "   ${YELLOW}$ORACLE_IP${NC}"
    echo ""
    echo "3. Test connectivity from Claude Desktop"
    echo ""
    echo "4. Set up backups (optional):"
    echo -e "   ${YELLOW}ssh -i $SSH_KEY $SSH_USER@$ORACLE_IP${NC}"
    echo -e "   ${YELLOW}nano ~/backup-mcp-gateway.sh${NC}"
    echo "   (See ORACLE_CLOUD_SETUP.md for backup script)"
    echo ""
    echo "5. Stop local Mac container:"
    echo -e "   ${YELLOW}cd $PROJECT_DIR${NC}"
    echo -e "   ${YELLOW}docker compose down${NC}"
    echo ""
    echo "Useful commands:"
    echo -e "  ${BLUE}# SSH into Oracle instance${NC}"
    echo -e "  ${YELLOW}ssh -i $SSH_KEY $SSH_USER@$ORACLE_IP${NC}"
    echo ""
    echo -e "  ${BLUE}# View logs${NC}"
    echo -e "  ${YELLOW}docker logs -f mcp-gateway${NC}"
    echo ""
    echo -e "  ${BLUE}# Restart container${NC}"
    echo -e "  ${YELLOW}docker restart mcp-gateway${NC}"
    echo ""
    echo -e "  ${BLUE}# Check status${NC}"
    echo -e "  ${YELLOW}docker ps${NC}"
    echo ""
    echo "For detailed setup instructions, see: ORACLE_CLOUD_SETUP.md"
    echo ""
}

# Main execution
main() {
    clear

    print_header "MCP Gateway - Oracle Cloud Deployment"
    echo ""

    check_requirements
    get_oracle_ip "$1"
    test_ssh_connection
    export_docker_image
    export_data_volume
    export_project_files
    transfer_files
    deploy_on_oracle
    verify_deployment
    cleanup_local
    display_next_steps
}

# Run main function
main "$@"
