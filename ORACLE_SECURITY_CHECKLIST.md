# Oracle Cloud Security Hardening Checklist

Complete security checklist for your MCP Gateway deployment on Oracle Cloud.

---

## Pre-Deployment Security

### SSH Key Management

- [ ] **Generate dedicated SSH key** (don't reuse personal keys)
  ```bash
  ssh-keygen -t ed25519 -C "oracle-mcp-gateway" -f ~/.ssh/oracle-mcp-gateway.key
  ```

- [ ] **Set correct permissions** on private key
  ```bash
  chmod 600 ~/.ssh/oracle-mcp-gateway.key
  ```

- [ ] **Back up SSH keys** to secure location (password manager, encrypted drive)

- [ ] **Document key location** in your password manager

### API Keys and Secrets

- [ ] **Audit .env file** for sensitive credentials
  ```bash
  cat .env | grep -i "api\|key\|token\|secret\|password"
  ```

- [ ] **Verify no secrets in git history**
  ```bash
  git log --all --full-history --source -- .env
  ```

- [ ] **Use environment-specific secrets** (different keys for prod/dev)

- [ ] **Rotate API keys** before migration if compromised

---

## Oracle Cloud Infrastructure Security

### Instance Security

- [ ] **Choose strong instance name** (not "mcp-gateway-prod" - use unique name)

- [ ] **Enable boot volume encryption** (default: on)

- [ ] **Enable in-transit encryption** for volumes (default: on)

- [ ] **Disable unused services** on instance

### Network Security - OCI Security Lists

- [ ] **Restrict SSH access** to your IP only
  - Go to: Security List → Ingress Rules → SSH rule
  - Change source from `0.0.0.0/0` to `YOUR_IP/32`
  ```
  Example: 203.0.113.45/32 (your public IP)
  ```

- [ ] **Remove default egress rules** (if not needed)
  - Review: Security List → Egress Rules
  - Remove unnecessary outbound traffic

- [ ] **Create separate security list** for MCP Gateway (isolation)
  - Don't use "Default Security List"
  - Create: "mcp-gateway-security-list"
  - Apply to instance's subnet

- [ ] **Minimize exposed ports**
  - Only expose ports actually needed
  - MCP Gateway: May not need ANY external ports (stdio only)

### Network Security - OS Level

- [ ] **Configure UFW firewall**
  ```bash
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow from YOUR_IP to any port 22  # Restrict SSH
  sudo ufw enable
  sudo ufw status
  ```

- [ ] **Install and configure Fail2Ban**
  ```bash
  sudo apt install fail2ban -y
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
  ```

- [ ] **Configure Fail2Ban for SSH**
  ```bash
  sudo nano /etc/fail2ban/jail.local
  ```
  Add:
  ```ini
  [sshd]
  enabled = true
  port = 22
  filter = sshd
  logpath = /var/log/auth.log
  maxretry = 3
  bantime = 3600
  ```

---

## SSH Hardening

- [ ] **Disable password authentication**
  ```bash
  sudo nano /etc/ssh/sshd_config
  ```
  Set:
  ```
  PasswordAuthentication no
  ChallengeResponseAuthentication no
  ```

- [ ] **Disable root login**
  ```
  PermitRootLogin no
  ```

- [ ] **Use SSH key authentication only**
  ```
  PubkeyAuthentication yes
  ```

- [ ] **Change default SSH port** (optional, reduces bot attacks)
  ```
  Port 2222  # Or any port 1024-65535
  ```
  **Important**: Update OCI Security List and UFW if you change port

- [ ] **Limit SSH access to specific users**
  ```
  AllowUsers ubuntu
  ```

- [ ] **Enable SSH key regeneration** on host key change
  ```
  StrictHostKeyChecking ask
  ```

- [ ] **Restart SSH service** after changes
  ```bash
  sudo systemctl restart sshd
  ```

- [ ] **Test SSH access** before closing current session
  ```bash
  # In new terminal
  ssh -i ~/.ssh/oracle-mcp-gateway.key ubuntu@ORACLE_IP
  ```

---

## Docker Security

### Container Security

- [ ] **Run containers as non-root user** (if possible)
  - Check Dockerfile for `USER` directive
  - MCP Gateway: Verify running as non-root

- [ ] **Limit container resources**
  ```yaml
  # In docker-compose.yml
  services:
    mcp-gateway:
      deploy:
        resources:
          limits:
            cpus: '2'
            memory: 8G
  ```

- [ ] **Use read-only file system** where possible
  ```yaml
  read_only: true
  tmpfs:
    - /tmp
  ```

- [ ] **Drop unnecessary capabilities**
  ```yaml
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE  # Only if needed
  ```

- [ ] **Enable security options**
  ```yaml
  security_opt:
    - no-new-privileges:true
  ```

### Docker Daemon Security

- [ ] **Enable Docker Content Trust** (image signing)
  ```bash
  echo 'export DOCKER_CONTENT_TRUST=1' >> ~/.bashrc
  source ~/.bashrc
  ```

- [ ] **Scan images for vulnerabilities**
  ```bash
  docker scan mcp-gateway:latest
  ```

- [ ] **Keep Docker updated**
  ```bash
  sudo apt update && sudo apt upgrade docker-ce docker-ce-cli
  ```

- [ ] **Limit Docker socket access**
  ```bash
  sudo chmod 660 /var/run/docker.sock
  ```

### Container Network Isolation

- [ ] **Use custom Docker network** (not default bridge)
  ```yaml
  networks:
    mcp-network:
      driver: bridge
      ipam:
        config:
          - subnet: 172.28.0.0/16
  ```

- [ ] **Disable inter-container communication** (if not needed)
  ```bash
  sudo nano /etc/docker/daemon.json
  ```
  Add:
  ```json
  {
    "icc": false
  }
  ```

---

## Application Security

### Environment Variables

- [ ] **Restrict .env file permissions**
  ```bash
  chmod 600 ~/mcp-gateway/.env
  ```

- [ ] **Use secrets management** instead of .env (production)
  - Consider: HashiCorp Vault, AWS Secrets Manager, Azure Key Vault
  - Or: OCI Vault (Oracle's secrets manager)

- [ ] **Audit environment variables** in running container
  ```bash
  docker exec mcp-gateway env
  ```

- [ ] **Never log secrets** (check application logs)
  ```bash
  docker logs mcp-gateway | grep -i "api.*key\|token\|secret"
  ```

### API Key Security

- [ ] **Rotate API keys** every 90 days
  - Cloudflare
  - GitHub
  - Firecrawl
  - Neon Database
  - Twilio
  - ElevenLabs
  - Brave Search
  - Context7

- [ ] **Use minimum required permissions** for API keys
  - Example: GitHub token with only repo access, not admin

- [ ] **Monitor API key usage** for anomalies
  - Check service dashboards for unusual activity

- [ ] **Revoke old API keys** after rotation

### MCP Server Configuration

- [ ] **Review config.json** for security issues
  ```bash
  cat ~/mcp-gateway/config.json
  ```

- [ ] **Validate all MCP server commands** are legitimate
  - Ensure no shell injection vulnerabilities
  - Verify all `command` and `args` fields

- [ ] **Disable unused MCP servers**
  ```json
  {
    "servers": {
      "unused-server": {
        "disabled": true
      }
    }
  }
  ```

---

## System Security

### Operating System Hardening

- [ ] **Enable automatic security updates**
  ```bash
  sudo apt install unattended-upgrades -y
  sudo dpkg-reconfigure --priority=low unattended-upgrades
  ```

- [ ] **Configure automatic security patches only**
  ```bash
  sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
  ```
  Ensure:
  ```
  Unattended-Upgrade::Allowed-Origins {
      "${distro_id}:${distro_codename}-security";
  };
  ```

- [ ] **Keep system updated**
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

- [ ] **Remove unnecessary packages**
  ```bash
  sudo apt autoremove -y
  ```

- [ ] **Disable unused services**
  ```bash
  sudo systemctl list-unit-files --state=enabled
  sudo systemctl disable [unused-service]
  ```

### Audit and Logging

- [ ] **Enable audit logging** (auditd)
  ```bash
  sudo apt install auditd audispd-plugins -y
  sudo systemctl enable auditd
  sudo systemctl start auditd
  ```

- [ ] **Configure log retention**
  ```bash
  sudo nano /etc/logrotate.d/rsyslog
  ```
  Set:
  ```
  rotate 30  # Keep 30 days of logs
  daily
  compress
  ```

- [ ] **Monitor auth logs** for suspicious activity
  ```bash
  sudo tail -f /var/log/auth.log
  ```

- [ ] **Set up centralized logging** (optional)
  - Consider: Oracle Cloud Logging, ELK stack, Papertrail

- [ ] **Enable Docker logging**
  ```yaml
  # In docker-compose.yml
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"
  ```

### User Management

- [ ] **Disable unused user accounts**
  ```bash
  sudo passwd -l [username]  # Lock account
  ```

- [ ] **Set strong password policy** (if using passwords)
  ```bash
  sudo nano /etc/security/pwquality.conf
  ```

- [ ] **Review sudo privileges**
  ```bash
  sudo visudo
  ```

- [ ] **Enable sudo password timeout**
  ```
  Defaults timestamp_timeout=5  # Require password every 5 minutes
  ```

---

## Backup Security

### Backup Configuration

- [ ] **Encrypt backups** at rest
  ```bash
  # Using GPG encryption
  tar -czf - /data | gpg --encrypt --recipient your@email.com > backup.tar.gz.gpg
  ```

- [ ] **Store backups off-instance**
  - Oracle Cloud Object Storage
  - External storage service
  - Different availability domain

- [ ] **Test backup restoration** regularly
  ```bash
  # Restore to test directory
  docker run --rm -v test-volume:/data -v $(pwd):/backup alpine tar -xzf /backup/test.tar.gz
  ```

- [ ] **Secure backup script** permissions
  ```bash
  chmod 700 ~/backup-mcp-gateway.sh
  ```

- [ ] **Rotate backup encryption keys** annually

### Backup Access Control

- [ ] **Restrict backup directory** permissions
  ```bash
  chmod 700 ~/backups
  ```

- [ ] **Use separate credentials** for backup storage
  - Don't reuse production API keys

---

## Monitoring and Alerting

### Security Monitoring

- [ ] **Monitor failed SSH attempts**
  ```bash
  sudo grep "Failed password" /var/log/auth.log | tail -20
  ```

- [ ] **Check for rootkit** (optional, but recommended)
  ```bash
  sudo apt install rkhunter -y
  sudo rkhunter --update
  sudo rkhunter --check
  ```

- [ ] **Monitor resource usage** for anomalies
  ```bash
  docker stats mcp-gateway --no-stream
  htop
  ```

- [ ] **Set up intrusion detection** (optional)
  ```bash
  sudo apt install aide -y  # Advanced Intrusion Detection Environment
  sudo aideinit
  ```

### Alerting

- [ ] **Configure email alerts** for security events
  - SSH login notifications
  - Failed authentication attempts
  - System updates available

- [ ] **Set up Oracle Cloud Monitoring** (free tier)
  - Go to: Observability & Management → Monitoring
  - Create alarm for high CPU/memory usage
  - Create alarm for disk space

- [ ] **Monitor Docker container health**
  ```yaml
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 1m
    timeout: 10s
    retries: 3
  ```

---

## Incident Response

### Preparation

- [ ] **Document incident response plan**
  - Who to contact
  - Steps to isolate compromised system
  - Backup restoration procedure

- [ ] **Save forensics script** for quick triage
  ```bash
  cat > ~/incident-triage.sh << 'EOF'
  #!/bin/bash
  echo "=== Active Connections ==="
  sudo netstat -tunapl
  echo ""
  echo "=== Recent Auth Logs ==="
  sudo tail -50 /var/log/auth.log
  echo ""
  echo "=== Docker Containers ==="
  docker ps -a
  echo ""
  echo "=== Recent Commands ==="
  history | tail -50
  EOF
  chmod +x ~/incident-triage.sh
  ```

- [ ] **Create snapshot** of working system (for rollback)
  - Oracle Console → Compute → Instances → Create Custom Image

### Response Procedures

- [ ] **Know how to stop container immediately**
  ```bash
  docker stop mcp-gateway
  ```

- [ ] **Know how to isolate instance** from network
  - Oracle Console → Networking → Security Lists → Remove all rules

- [ ] **Know how to access logs** when SSH is compromised
  - Oracle Console → Compute → Instances → Console Connection

- [ ] **Test snapshot restoration** procedure

---

## Compliance and Best Practices

### Regular Maintenance

- [ ] **Weekly security audit** (automated)
  ```bash
  # Create weekly-audit.sh
  #!/bin/bash
  echo "Security Audit: $(date)"
  echo "=== Failed SSH Attempts ==="
  sudo grep "Failed password" /var/log/auth.log | tail -10
  echo "=== Disk Usage ==="
  df -h
  echo "=== Docker Resource Usage ==="
  docker stats mcp-gateway --no-stream
  echo "=== UFW Status ==="
  sudo ufw status
  echo "=== Listening Ports ==="
  sudo netstat -tuln
  ```

- [ ] **Monthly security updates**
  ```bash
  sudo apt update && sudo apt upgrade -y
  docker pull ubuntu:22.04  # Update base images
  ```

- [ ] **Quarterly API key rotation**

- [ ] **Annual security review** of entire infrastructure

### Documentation

- [ ] **Document all security configurations**
  - Firewall rules
  - SSH configuration
  - Monitoring setup
  - API key rotation schedule

- [ ] **Maintain security changelog**
  - Date: What changed
  - Why: Reason for change
  - Who: Person responsible

- [ ] **Create runbook** for common security tasks
  - SSH key rotation
  - API key rotation
  - Incident response
  - Backup restoration

---

## Post-Deployment Verification

### Security Testing

- [ ] **Scan open ports** from external network
  ```bash
  # From your Mac
  nmap -Pn ORACLE_IP
  ```
  Expected: Only port 22 (SSH) or your custom SSH port

- [ ] **Test SSH access** with wrong key (should fail)
  ```bash
  ssh ubuntu@ORACLE_IP
  # Should fail: Permission denied (publickey)
  ```

- [ ] **Test SSH brute force protection** (Fail2Ban)
  ```bash
  # After 3 failed attempts, IP should be banned
  sudo fail2ban-client status sshd
  ```

- [ ] **Verify firewall is active**
  ```bash
  sudo ufw status
  # Should show: Status: active
  ```

- [ ] **Check for unnecessary services**
  ```bash
  sudo netstat -tuln | grep LISTEN
  # Should only show necessary ports
  ```

### Application Security Testing

- [ ] **Test API key permissions** are minimum required
  - Attempt unauthorized action with each key
  - Verify access denied

- [ ] **Review Docker container security**
  ```bash
  docker inspect mcp-gateway | grep -A10 SecurityOpt
  ```

- [ ] **Check for exposed secrets** in logs
  ```bash
  docker logs mcp-gateway | grep -i "password\|secret\|api.*key"
  # Should find nothing sensitive
  ```

---

## Security Checklist Summary

**Critical** (Do immediately):
- [ ] Restrict SSH to your IP only
- [ ] Disable password authentication
- [ ] Set .env file permissions to 600
- [ ] Enable automatic security updates
- [ ] Set up Fail2Ban

**Important** (Do within first week):
- [ ] Configure UFW firewall
- [ ] Enable audit logging
- [ ] Set up backups
- [ ] Monitor logs for anomalies
- [ ] Create incident response plan

**Recommended** (Do within first month):
- [ ] Rotate all API keys
- [ ] Set up intrusion detection
- [ ] Configure centralized logging
- [ ] Create security documentation
- [ ] Test backup restoration

**Ongoing**:
- [ ] Weekly: Review logs for suspicious activity
- [ ] Monthly: Apply security updates
- [ ] Quarterly: Rotate API keys
- [ ] Annually: Full security audit

---

## Additional Resources

- **OWASP Docker Security**: https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- **CIS Ubuntu Benchmark**: https://www.cisecurity.org/benchmark/ubuntu_linux
- **Oracle Cloud Security Best Practices**: https://docs.oracle.com/en-us/iaas/Content/Security/Reference/security_best_practices.htm

---

*Checklist created: 2025-11-10*
*Last updated: 2025-11-10*
*Next review: Weekly*
