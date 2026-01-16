# MCP Gateway API Setup Guide

This guide walks you through obtaining API keys for all MCP servers in the gateway.

---

## 🔥 High Priority APIs (Recommended to Set Up First)

### 1. Cloudflare API Token

**What it enables:** Workers, KV, R2, D1, DNS, Analytics, WAF

**Steps:**
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use template "Edit Cloudflare Workers" OR create custom token with:
   - Account: Cloudflare Workers Scripts (Edit)
   - Account: Workers KV Storage (Edit)
   - Account: Workers R2 Storage (Edit)
   - Account: D1 (Edit)
   - Zone: DNS (Edit) - if you want DNS management
   - Account: Analytics (Read)
4. Copy the token and add to `.env`:
   ```bash
   CLOUDFLARE_API_TOKEN=your_token_here
   ```
5. Get your Account ID from the Cloudflare dashboard (Workers & Pages > Overview)
   ```bash
   CLOUDFLARE_ACCOUNT_ID=dcdf236ac1ccf12a7cf95da7a3758ba1  # Already set
   ```

**Cost:** Free tier available (100,000 requests/day)

---

### 2. Stripe API Key

**What it enables:** Payment processing, customer management, subscriptions

**Steps:**
1. Go to https://dashboard.stripe.com/apikeys
2. Sign up/login to Stripe
3. In the Developers section, find "API keys"
4. Copy the "Secret key" (starts with `sk_test_` for test mode)
5. Add to `.env`:
   ```bash
   STRIPE_API_KEY=sk_test_your_key_here
   ```

**For production:** Use `sk_live_` key instead

**Cost:** Free to integrate, transaction fees apply (2.9% + $0.30 per charge)

---

### 3. Twilio Account Credentials

**What it enables:** SMS, Voice calls, WhatsApp, Video

**Steps:**
1. Go to https://www.twilio.com/try-twilio
2. Sign up for a free trial account
3. After signup, go to https://console.twilio.com/
4. Find your credentials on the dashboard:
   - Account SID (starts with `AC`)
   - Auth Token (click "Show" to reveal)
5. Add to `.env`:
   ```bash
   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   TWILIO_AUTH_TOKEN=your_auth_token_here
   ```

**Cost:** Free trial with $15 credit, then pay-as-you-go ($0.0075/SMS)

---

## 📊 Database APIs

### 4. PostgreSQL Connection String

**What it enables:** PostgreSQL database operations

**If you have existing Postgres:**
```bash
POSTGRES_CONNECTION_STRING=postgresql://username:password@host:5432/database
```

**To create new Postgres database (free options):**

**Option A: Neon (Serverless Postgres)**
1. Go to https://neon.tech/
2. Sign up and create a project
3. Copy the connection string
4. Add to `.env`:
   ```bash
   NEON_API_KEY=your_neon_api_key
   POSTGRES_CONNECTION_STRING=postgresql://user:pass@host.neon.tech/dbname
   ```

**Option B: Supabase (Free tier)**
1. Go to https://supabase.com/
2. Create project
3. Get connection string from Settings > Database
4. Add to `.env`

**Option C: Railway (Free tier)**
1. Go to https://railway.app/
2. Create new Postgres database
3. Copy connection string

**Cost:** Neon/Supabase free tier available

---

### 5. Neon Database API Key

**What it enables:** Neon-specific database management, branching, analytics

**Steps:**
1. Go to https://console.neon.tech/
2. Navigate to Account Settings > API Keys
3. Click "Generate New API Key"
4. Add to `.env`:
   ```bash
   NEON_API_KEY=your_neon_api_key_here
   ```

**Note:** Currently disabled in your config. To enable:
```bash
npm run mcp enable neon
```

**Cost:** Free tier: 0.5 GB storage, 1 database

---

## ☁️ Cloud Platform APIs

### 6. Azure Credentials

**What it enables:** Azure VM, Storage, Functions, App Services

**Steps:**
1. Go to https://portal.azure.com/
2. Sign in/create Azure account
3. Create a Service Principal:
   ```bash
   az ad sp create-for-rbac --name "mcp-gateway" --role contributor
   ```
4. This will output:
   ```json
   {
     "appId": "your-client-id",
     "password": "your-client-secret",
     "tenant": "your-tenant-id"
   }
   ```
5. Get subscription ID: `az account show --query id`
6. Add to `.env`:
   ```bash
   AZURE_SUBSCRIPTION_ID=your_subscription_id
   AZURE_TENANT_ID=your_tenant_id
   AZURE_CLIENT_ID=your_client_id
   AZURE_CLIENT_SECRET=your_client_secret
   ```

**Alternative (Portal method):**
1. Azure Portal > Azure Active Directory > App Registrations
2. New Registration > Create
3. Certificates & Secrets > New client secret
4. Copy values to `.env`

**Cost:** Free trial: $200 credit for 30 days

---

## 💬 Communication APIs

### 7. Slack Bot Token

**What it enables:** Send messages, read channels, manage workspace

**Steps:**
1. Go to https://api.slack.com/apps
2. Click "Create New App" > "From scratch"
3. Name it and select your workspace
4. Go to "OAuth & Permissions"
5. Add Bot Token Scopes (minimum):
   - `channels:read`
   - `chat:write`
   - `users:read`
6. Install app to workspace
7. Copy "Bot User OAuth Token" (starts with `xoxb-`)
8. Get Team ID from workspace settings or:
   ```bash
   # Visit: https://api.slack.com/methods/auth.test/test
   ```
9. Add to `.env`:
   ```bash
   SLACK_BOT_TOKEN=xoxb-your-token-here
   SLACK_TEAM_ID=T12345678
   ```

**Cost:** Free

---

## 🔍 Monitoring & Analytics

### 8. Sentry Error Tracking

**What it enables:** Error monitoring, performance tracking, issue management

**Steps:**
1. Go to https://sentry.io/signup/
2. Create account and organization
3. Go to Settings > Account > API > Auth Tokens
4. Create new token with scopes:
   - `project:read`
   - `project:write`
   - `event:read`
5. Add to `.env`:
   ```bash
   SENTRY_AUTH_TOKEN=your_auth_token_here
   SENTRY_ORG=your_org_slug
   ```

**Cost:** Free tier: 5K events/month

---

## 📁 Storage & File APIs

### 9. Google Drive OAuth

**What it enables:** Read/write Google Drive files, manage sharing

**Steps:**
1. Go to https://console.cloud.google.com/
2. Create new project or select existing
3. Enable Google Drive API:
   - APIs & Services > Library > Search "Google Drive API" > Enable
4. Create OAuth Credentials:
   - APIs & Services > Credentials > Create Credentials > OAuth Client ID
   - Application type: "Web application"
   - Authorized redirect URIs: `http://localhost:3000/oauth/callback`
5. Copy Client ID and Client Secret
6. Add to `.env`:
   ```bash
   GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your_client_secret
   GOOGLE_REDIRECT_URI=http://localhost:3000/oauth/callback  # Already set
   ```

**Cost:** Free (subject to Drive storage limits)

---

## 🎯 Quick Setup Commands

After adding API keys to `.env`, verify they work:

```bash
# Rebuild and restart gateway
npm run build
npm start

# Or in dev mode
npm run dev
```

To check which servers are connected:
```bash
# Check the gateway logs on startup - it will show which servers initialized successfully
```

---

## 🔐 Security Best Practices

1. **Never commit `.env` file** (already in `.gitignore`)
2. **Use separate keys for dev/prod**
3. **Rotate keys regularly** (every 90 days)
4. **Use minimum required permissions** for each API token
5. **Monitor API usage** to detect unauthorized access
6. **Use environment-specific keys**:
   - `STRIPE_API_KEY`: use `sk_test_*` for dev, `sk_live_*` for prod
   - `TWILIO`: create separate projects for dev/prod

---

## 📊 Priority Order Recommendation

**If you want to set up gradually, do them in this order:**

1. ✅ **Cloudflare** (already have account ID, just need token) - Most versatile
2. ✅ **Stripe** - Essential for payments
3. ✅ **PostgreSQL/Neon** - Database access
4. ⚠️ **Twilio** - If you need SMS/voice
5. ⚠️ **Slack** - If you need workspace integration
6. ⚠️ **Google Drive** - If you need file storage
7. ⚠️ **Sentry** - Nice to have for monitoring
8. ⚠️ **Azure** - Only if using Azure cloud

---

## 🆘 Troubleshooting

### API Key Not Working?

1. **Check formatting**: No extra spaces, quotes, or newlines
2. **Verify permissions**: Token has required scopes
3. **Check expiration**: Some tokens expire
4. **Test directly**: Use API provider's test console
5. **Check logs**: `npm run dev` shows connection errors

### Server Won't Start?

```bash
# Check which server is failing
npm run dev

# Disable problematic server temporarily
npm run mcp disable [server-name]
```

### Rate Limits Hit?

- **Cloudflare**: 100K requests/day (free tier)
- **Stripe**: No limits for API calls
- **Twilio**: Depends on account type
- **GitHub**: 5K requests/hour (already configured)
- **Brave Search**: 2K requests/month (free tier)

---

**Last Updated:** 2025-10-27
