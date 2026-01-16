#!/bin/bash

# Interactive script to add API keys to .env file

ENV_FILE=".env"
BACKUP_FILE=".env.backup"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   MCP Gateway API Key Setup Helper    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Backup existing .env
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✓${NC} Backed up .env to .env.backup"
fi

# Function to add or update API key
add_api_key() {
    local key_name=$1
    local description=$2
    local current_value=$(grep "^${key_name}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$description${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ -n "$current_value" ] && [ "$current_value" != "" ]; then
        echo -e "Current value: ${GREEN}[SET]${NC}"
        read -p "Update? (y/N): " update
        if [[ ! "$update" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Skipped${NC}"
            return
        fi
    fi

    read -p "Enter $key_name: " value

    if [ -n "$value" ]; then
        # Remove old value if exists
        sed -i.tmp "s|^${key_name}=.*|${key_name}=${value}|" "$ENV_FILE"
        rm -f "${ENV_FILE}.tmp"
        echo -e "${GREEN}✓${NC} Added $key_name"
    else
        echo -e "${RED}✗${NC} Skipped (empty value)"
    fi
}

# Main menu
while true; do
    echo ""
    echo -e "${BLUE}Select service to configure:${NC}"
    echo ""
    echo "  1) Cloudflare (Workers, KV, R2, D1)"
    echo "  2) Stripe (Payments)"
    echo "  3) Twilio (SMS, Voice)"
    echo "  4) Neon (Serverless Postgres)"
    echo "  5) PostgreSQL (Database)"
    echo "  6) Azure (Cloud Services)"
    echo "  7) Slack (Messaging)"
    echo "  8) Google Drive (File Storage)"
    echo "  9) Sentry (Error Tracking)"
    echo " 10) Show current configuration"
    echo "  0) Exit"
    echo ""
    read -p "Choice: " choice

    case $choice in
        1)
            add_api_key "CLOUDFLARE_API_TOKEN" "Cloudflare API Token (https://dash.cloudflare.com/profile/api-tokens)"
            ;;
        2)
            add_api_key "STRIPE_API_KEY" "Stripe Secret Key (https://dashboard.stripe.com/apikeys)"
            ;;
        3)
            add_api_key "TWILIO_ACCOUNT_SID" "Twilio Account SID (https://console.twilio.com)"
            add_api_key "TWILIO_AUTH_TOKEN" "Twilio Auth Token"
            ;;
        4)
            add_api_key "NEON_API_KEY" "Neon API Key (https://console.neon.tech)"
            ;;
        5)
            add_api_key "POSTGRES_CONNECTION_STRING" "PostgreSQL Connection String (postgresql://user:pass@host:5432/db)"
            ;;
        6)
            add_api_key "AZURE_SUBSCRIPTION_ID" "Azure Subscription ID"
            add_api_key "AZURE_TENANT_ID" "Azure Tenant ID"
            add_api_key "AZURE_CLIENT_ID" "Azure Client ID"
            add_api_key "AZURE_CLIENT_SECRET" "Azure Client Secret"
            ;;
        7)
            add_api_key "SLACK_BOT_TOKEN" "Slack Bot Token (xoxb-...)"
            add_api_key "SLACK_TEAM_ID" "Slack Team ID"
            ;;
        8)
            add_api_key "GOOGLE_CLIENT_ID" "Google Client ID"
            add_api_key "GOOGLE_CLIENT_SECRET" "Google Client Secret"
            ;;
        9)
            add_api_key "SENTRY_AUTH_TOKEN" "Sentry Auth Token"
            add_api_key "SENTRY_ORG" "Sentry Organization Slug"
            ;;
        10)
            echo ""
            echo -e "${BLUE}Current API Configuration:${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

            check_key() {
                local key=$1
                local value=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)
                if [ -n "$value" ] && [ "$value" != "" ]; then
                    echo -e "  ${GREEN}✓${NC} $key"
                else
                    echo -e "  ${RED}✗${NC} $key"
                fi
            }

            echo ""
            echo -e "${BLUE}Configured APIs:${NC}"
            check_key "CONTEXT7_API_KEY"
            check_key "GITHUB_PERSONAL_ACCESS_TOKEN"
            check_key "BRAVE_API_KEY"
            check_key "FIRECRAWL_API_KEY"
            check_key "ELEVENLABS_API_KEY"

            echo ""
            echo -e "${BLUE}Missing APIs:${NC}"
            check_key "CLOUDFLARE_API_TOKEN"
            check_key "STRIPE_API_KEY"
            check_key "TWILIO_ACCOUNT_SID"
            check_key "NEON_API_KEY"
            check_key "AZURE_SUBSCRIPTION_ID"
            check_key "SLACK_BOT_TOKEN"
            check_key "POSTGRES_CONNECTION_STRING"
            check_key "GOOGLE_CLIENT_ID"
            check_key "SENTRY_AUTH_TOKEN"

            echo ""
            ;;
        0)
            echo ""
            echo -e "${GREEN}✓${NC} Configuration saved to .env"
            echo -e "${BLUE}Run 'npm run build && npm start' to apply changes${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
done
