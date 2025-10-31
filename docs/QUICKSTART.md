# 🚀 CF-DEMO-REPO Quick Start Guide

Get your Cloudflare automation platform up and running in **5 minutes**!

## Prerequisites Check

Before starting, ensure you have:

- [ ] Docker installed and running
- [ ] 8GB+ RAM available
- [ ] 20GB+ free disk space
- [ ] Cloudflare API Token ready ([Create one here](https://dash.cloudflare.com/profile/api-tokens))

## Step 1: Clone and Setup (2 minutes)

```bash
# Clone the repository
git clone https://github.com/your-org/CF-DEMO-REPO.git
cd CF-DEMO-REPO

# Check prerequisites
make check-env

# If anything is missing, install dependencies
make install-deps
```

## Step 2: Configure Credentials (1 minute)

```bash
# Copy example configuration
cp config/credentials.yml.example config/credentials.yml

# Edit with your Cloudflare token
nano config/credentials.yml
# or
vim config/credentials.yml
```

**Minimum required configuration:**

```yaml
cloudflare_api_token: "YOUR_ACTUAL_CLOUDFLARE_API_TOKEN"
```

Get your token from: https://dash.cloudflare.com/profile/api-tokens

**Required permissions:**
- Zone:Read, Zone:Edit
- DNS:Read, DNS:Edit
- Page Rules:Read, Page Rules:Edit (optional)
- Zone WAF:Read, Zone WAF:Edit (optional)

## Step 3: Deploy Everything (2 minutes)

```bash
# One command to rule them all!
make deploy-all
```

This will:
1. ✅ Setup Python environment
2. ✅ Create Kind Kubernetes cluster
3. ✅ Deploy MetalLB load balancer
4. ✅ Build custom AWX image
5. ✅ Deploy AWX
6. ✅ Configure AWX with Cloudflare templates

**Note:** This takes ~5-10 minutes depending on your internet connection and hardware.

## Step 4: Access AWX

```bash
# Port-forward AWX to localhost
make awx
```

This will display:
```
═══════════════════════════════════════════════════
  AWX Web Interface
═══════════════════════════════════════════════════
  URL:      http://localhost:8080
  Username: admin
  Password: <generated-password>
═══════════════════════════════════════════════════
```

Open http://localhost:8080 in your browser and log in!

## Step 5: Test Cloudflare Integration

```bash
# In a new terminal (keep AWX port-forward running)
make test-cloudflare
```

Expected output:
```
✅ Cloudflare API token is valid!
```

## Step 6: Run Your First Automation

### Via Command Line:

```bash
# List DNS records
make cf-dns-list DOMAIN=your-domain.com

# Create a DNS record
make cf-run-playbook \
  PLAYBOOK=dns_management.yml \
  ACTION=create \
  DOMAIN=your-domain.com \
  RECORD_NAME=api \
  RECORD_TYPE=A \
  RECORD_VALUE=192.168.1.100
```

### Via AWX Web Interface:

1. Navigate to **Resources → Templates**
2. Click **🚀 Launch** on "Cloudflare DNS Management"
3. Fill in the survey:
   - **Action**: create
   - **Domain**: your-domain.com
   - **Record Name**: test
   - **Record Type**: A
   - **Record Value**: 192.168.1.1
4. Click **Next** → **Launch**
5. Watch the job execute in real-time!

## 🎉 You're All Set!

You now have a fully functional Cloudflare automation platform!

## Common Tasks

### Check Status
```bash
make status
```

### View AWX Password
```bash
make awx-password
```

### View AWX Logs
```bash
make awx-logs
```

### Restart AWX
```bash
make awx-restart
```

### List All Cloudflare Zones
```bash
make cf-zones
```

### Backup Configuration
```bash
make backup
```

## Next Steps

1. **Read the full documentation:**
   - [Architecture Overview](ARCHITECTURE.md)
   - [Deployment Guide](DEPLOYMENT.md)
   - [Cloudflare Operations](CLOUDFLARE_OPS.md)

2. **Explore AWX:**
   - Create additional job templates
   - Set up workflows
   - Configure notifications
   - Add team members

3. **Customize playbooks:**
   - Edit `playbooks/cloudflare/` files
   - Create new roles in `roles/`
   - Add more automation tasks

4. **Set up for production:**
   - Configure proper credentials vault
   - Set up backup automation
   - Configure monitoring and alerts
   - Review security settings

## Troubleshooting

### AWX not accessible?
```bash
# Check AWX status
make awx-status

# View logs
make awx-logs

# Restart AWX
make awx-restart
```

### Cloudflare API errors?
```bash
# Test your token
make test-cloudflare

# Check token permissions at:
# https://dash.cloudflare.com/profile/api-tokens
```

### Cluster issues?
```bash
# Check cluster
kubectl get nodes
kubectl get pods -A

# Recreate cluster
make clean-cluster
make setup-cluster
```

### Port already in use?
```bash
# Kill existing port-forwards
pkill -f "kubectl port-forward"

# Try again
make awx
```

## Clean Up

### Remove AWX only:
```bash
make clean
```

### Remove everything:
```bash
make clean-all
```

### Start fresh:
```bash
make reset  # Removes and redeploys everything
```

## Getting Help

- **Issues:** [GitHub Issues](https://github.com/your-org/CF-DEMO-REPO/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-org/CF-DEMO-REPO/discussions)
- **Documentation:** Check the `docs/` directory

## Quick Reference Card

```bash
# Setup
make deploy-all          # Complete deployment
make awx                 # Access AWX UI
make awx-password        # Show password

# Operations
make test-cloudflare     # Test API
make cf-zones            # List zones
make cf-dns-list         # List DNS records
make status              # Show status

# Maintenance
make backup              # Backup config
make awx-restart         # Restart AWX
make validate            # Run checks

# Cleanup
make clean               # Remove AWX
make clean-all           # Remove everything
```

---

**🎯 Pro Tip:** Add `alias cfdemo='cd /path/to/CF-DEMO-REPO'` to your shell profile for quick access!

**📚 Learn More:** Check out the [full documentation](../README.md) for advanced features and configuration options.
