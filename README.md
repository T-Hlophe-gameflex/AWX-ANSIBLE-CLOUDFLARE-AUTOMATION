# Cloudflare Automation with AWX

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-blue.svg)](https://www.ansible.com/)
[![AWX](https://img.shields.io/badge/AWX-24.6.1-orange.svg)](https://github.com/ansible/awx)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.34+-blue.svg)](https://kubernetes.io/)

## 🚀 Overview

**CF-DEMO-REPO** is a production-ready, enterprise-grade infrastructure automation platform that combines:

- **Ansible AWX** for workflow orchestration and job scheduling
- **Cloudflare API Integration** for automated DNS and security management
- **Kubernetes** cluster management via Kind (local) or production clusters
- **Patched AWX Image** with custom Cloudflare survey support
- **One-Command Deployment** via comprehensive Makefile

This project follows the architectural patterns from proven enterprise setups, providing a complete, batteries-included solution for Cloudflare automation at scale.

## ✨ Features

### Core Capabilities
- 🎯 **One-Command Setup**: Complete infrastructure deployment with `make deploy`
- 🎭 **Pre-configured AWX**: Job templates, inventories, and workflows ready to use
- ☁️ **Cloudflare Automation**: DNS, WAF rules, Page Rules, rate limiting, and more
- 🔐 **Secure by Default**: Token-based authentication, encrypted credentials
- 📊 **Survey-Driven Workflows**: Interactive forms for Cloudflare operations
- 🚀 **GitOps Ready**: Infrastructure as Code with version control
- 🌐 **Multi-Environment**: Support for dev, staging, and production

### Technical Highlights
- Custom AWX image with Cloudflare API survey support
- Ansible roles following enterprise best practices
- Comprehensive inventory management (group_vars, host_vars)
- MetalLB for LoadBalancer services on bare-metal/Kind
- Helm charts for all Kubernetes components
- Automated backup and restore capabilities

## 📋 Prerequisites

### Required Software
- **Docker** (20.10+)
- **Kind** (0.20+) or access to Kubernetes cluster
- **kubectl** (1.28+)
- **Helm** (3.12+)
- **Python** (3.11+)
- **Ansible** (2.15+)
- **Make** (GNU Make)

### Required Credentials
- **Cloudflare API Token** with appropriate permissions
- **GitHub Token** (optional, for private repositories)

### System Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 20GB free space
- **OS**: macOS, Linux, or WSL2

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/your-org/CF-DEMO-REPO.git
cd CF-DEMO-REPO

# Copy example configuration
cp config/credentials.yml.example config/credentials.yml
```

### 2. Set Your Cloudflare Token

Edit `config/credentials.yml`:

```yaml
---
cloudflare_api_token: "YOUR_CLOUDFLARE_API_TOKEN_HERE"
cloudflare_account_id: "YOUR_ACCOUNT_ID"  # Optional
cloudflare_zone_id: "YOUR_DEFAULT_ZONE_ID"  # Optional
```

### 3. Deploy Everything

```bash
# Complete setup: Python env + Cluster + AWX + Cloudflare
make deploy

# This will:
# 1. Install Python dependencies
# 2. Create Kind Kubernetes cluster
# 3. Deploy MetalLB for LoadBalancer support
# 4. Build and push custom AWX image
# 5. Deploy AWX with Helm
# 6. Configure AWX with Cloudflare templates
# 7. Create inventories and credentials
```

### 4. Access AWX

```bash
# Port-forward AWX to localhost
make awx

# Open browser to: http://localhost:8080
# Username: admin
# Password: (displayed in terminal)
```

## 📖 Documentation

- [**Quick Start Guide**](docs/QUICKSTART.md) - Get up and running in 5 minutes
- [**Deployment Guide**](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [**Architecture Overview**](docs/ARCHITECTURE.md) - System design and components
- [**Cloudflare Operations**](docs/CLOUDFLARE_OPS.md) - Available Cloudflare automations
- [**AWX Configuration**](docs/AWX_CONFIG.md) - Job templates and workflows
- [**Troubleshooting**](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🏗️ Project Structure

```
CF-DEMO-REPO/
├── Makefile                    # Main automation interface
├── ansible.cfg                 # Ansible configuration
├── requirements.txt            # Python dependencies
├── requirements.yml            # Ansible collections/roles
│
├── config/                     # Configuration files
│   ├── credentials.yml.example # Credential template
│   └── awx-instance.yaml       # AWX deployment config
│
├── inventory/                  # Ansible inventories
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/
│   └── development/
│
├── playbooks/                  # Ansible playbooks
│   ├── cloudflare/
│   │   ├── dns_management.yml
│   │   ├── waf_rules.yml
│   │   ├── page_rules.yml
│   │   └── rate_limiting.yml
│   ├── awx_configure.yml
│   └── site.yml
│
├── roles/                      # Ansible roles
│   ├── cloudflare_dns/
│   ├── cloudflare_waf/
│   ├── cloudflare_ssl/
│   └── awx_setup/
│
├── awx-image/                  # Custom AWX Docker image
│   ├── Dockerfile
│   ├── jobs.py                 # Patched jobs.py
│   └── README.md
│
├── helm-charts/                # Helm charts
│   ├── awx/
│   ├── metallb/
│   └── values/
│
├── scripts/                    # Helper scripts
│   ├── setup-cluster.sh
│   ├── build-awx-image.sh
│   ├── configure-awx.sh
│   └── awx_survey_manager.sh
│
└── docs/                       # Documentation
    ├── QUICKSTART.md
    ├── DEPLOYMENT.md
    ├── ARCHITECTURE.md
    └── TROUBLESHOOTING.md
```

## 🎯 Common Use Cases

### DNS Management
```bash
# Via AWX UI: Navigate to Templates → "Cloudflare DNS Management"
# Or via CLI:
ansible-playbook playbooks/cloudflare/dns_management.yml \
  -e "zone_name=example.com" \
  -e "record_type=A" \
  -e "record_name=api" \
  -e "record_value=192.168.1.100"
```

### WAF Rule Deployment
```bash
# Via AWX: Templates → "Cloudflare WAF Rules"
ansible-playbook playbooks/cloudflare/waf_rules.yml \
  -e "zone_name=example.com" \
  -e "rule_action=block" \
  -e "rule_expression='(ip.src eq 192.0.2.0)'"
```

### SSL/TLS Configuration
```bash
# Via AWX: Templates → "Cloudflare SSL Settings"
ansible-playbook playbooks/cloudflare/ssl_config.yml \
  -e "zone_name=example.com" \
  -e "ssl_mode=full"
```

## 🔧 Makefile Targets

| Target | Description |
|--------|-------------|
| `make deploy` | Complete deployment (cluster + AWX + config) |
| `make setup-cluster` | Create Kubernetes cluster only |
| `make deploy-awx` | Deploy AWX to existing cluster |
| `make configure-awx` | Configure AWX with Cloudflare templates |
| `make awx` | Port-forward AWX UI to localhost |
| `make awx-status` | Check AWX deployment status |
| `make clean` | Remove all deployments |
| `make clean-cluster` | Delete entire cluster |
| `make test-cloudflare` | Test Cloudflare API connectivity |
| `make backup` | Backup AWX configuration |
| `make restore` | Restore AWX from backup |
| `make help` | Show all available targets |

## 🛠️ Configuration

### Ansible Variables

Key variables in `inventory/*/group_vars/all/`:

```yaml
# Cloudflare Configuration
cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
cloudflare_account_id: "your-account-id"
cloudflare_email: "your-email@example.com"

# AWX Configuration
awx_admin_password: "{{ vault_awx_admin_password }}"
awx_namespace: "awx"
awx_version: "24.6.1"

# Cluster Configuration
cluster_name: "cf-demo-cluster"
cluster_type: "kind"  # or "production"
metallb_ip_range: "172.18.255.200-172.18.255.250"
```

### Environment-Specific Overrides

Use inventory-specific `group_vars` for environment differences:

```
inventory/
├── production/group_vars/all/
│   ├── main.yml           # Production-specific settings
│   └── vault.yml          # Encrypted production credentials
├── staging/group_vars/all/
│   └── main.yml           # Staging-specific settings
└── development/group_vars/all/
    └── main.yml           # Development-specific settings
```

## 🧪 Testing

```bash
# Test Cloudflare API connectivity
make test-cloudflare

# Validate Ansible playbooks
make validate-playbooks

# Run integration tests
make test

# Check AWX health
make awx-status
```

## 📊 Monitoring

### AWX Dashboard
- Access: http://localhost:8080 (after `make awx`)
- View job execution history
- Monitor playbook runs in real-time
- Review logs and outputs

### Kubernetes Resources
```bash
# Check AWX pods
kubectl get pods -n awx

# Check AWX logs
kubectl logs -n awx -l app.kubernetes.io/name=awx-web

# Monitor all resources
make status
```

## 🔐 Security Best Practices

1. **Never commit credentials**: Use `vault.yml` with Ansible Vault
2. **Rotate tokens regularly**: Update Cloudflare API tokens periodically
3. **Use RBAC**: Configure AWX role-based access control
4. **Network policies**: Apply Kubernetes network policies in production
5. **Audit logs**: Enable and review AWX audit logs regularly

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Based on enterprise patterns from ansible-iom-master
- Cloudflare automation patterns from gameflex-devops-master
- AWX patching methodology from production deployments
- Kubernetes patterns from Kubespray

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-org/CF-DEMO-REPO/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/CF-DEMO-REPO/discussions)
- **Email**: devops@your-org.com

## 🗺️ Roadmap

- [ ] Multi-cloud DNS support (Route53, Azure DNS)
- [ ] Terraform integration for infrastructure
- [ ] CI/CD pipeline templates
- [ ] Slack/Teams notifications
- [ ] Grafana dashboards
- [ ] Auto-scaling based on job queue

---

**Made with ❤️ by the DevOps Team**

*"Automate all the things!"* 🚀
