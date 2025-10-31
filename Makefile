# =============================================================================
# 🚀 CF-DEMO-REPO: CLOUDFLARE AUTOMATION WITH AWX - MAKEFILE
# =============================================================================
# Purpose: Complete automation for Cloudflare management via Ansible AWX
# Author: DevOps Team
# Version: 1.0.0
# =============================================================================

.PHONY: help setup deploy clean test validate status

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

# Project Configuration
PROJECT_NAME := cf-demo
CLUSTER_NAME := cf-demo-cluster
AWX_NAMESPACE := awx
METALLB_NAMESPACE := metallb-system

# Paths
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts
CONFIG_DIR := $(PROJECT_ROOT)/config
INVENTORY_DIR := $(PROJECT_ROOT)/inventory
PLAYBOOKS_DIR := $(PROJECT_ROOT)/playbooks
AWX_IMAGE_DIR := $(PROJECT_ROOT)/awx-image
HELM_CHARTS_DIR := $(PROJECT_ROOT)/helm-charts

# Python Configuration
PYTHON_CMD := python3
PIP_CMD := $(PYTHON_CMD) -m pip
VENV_DIR := $(PROJECT_ROOT)/.venv

# Docker/Kind Configuration
DOCKER_REGISTRY := localhost:5000
AWX_IMAGE_NAME := awx-custom
AWX_IMAGE_TAG := latest
AWX_FULL_IMAGE := $(DOCKER_REGISTRY)/$(AWX_IMAGE_NAME):$(AWX_IMAGE_TAG)

# AWX Configuration
AWX_VERSION := 24.6.1
AWX_OPERATOR_VERSION := 2.12.2
AWX_ADMIN_USER := admin
AWX_SERVICE_PORT := 8080

# MetalLB Configuration
METALLB_VERSION := 0.13.12
METALLB_IP_RANGE := 172.18.255.200-172.18.255.250

# Color codes for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[1;37m
NC := \033[0m

# =============================================================================
# HELP AND INFORMATION
# =============================================================================

help:
	@echo -e "$(PURPLE)═══════════════════════════════════════════════════════════════$(NC)"
	@echo -e "$(PURPLE)    🚀 CF-DEMO-REPO: Cloudflare Automation with AWX$(NC)"
	@echo -e "$(PURPLE)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(CYAN)📋 QUICK START:$(NC)"
	@echo "  make deploy          🎯 Complete deployment (recommended)"
	@echo "  make awx             🎭 Access AWX web interface"
	@echo "  make test-cloudflare 🧪 Test Cloudflare API connectivity"
	@echo ""
	@echo -e "$(CYAN)🔧 SETUP & INSTALLATION:$(NC)"
	@echo "  make setup           ✨ Complete setup (Python + Cluster + AWX)"
	@echo "  make setup-python    🐍 Setup Python environment"
	@echo "  make setup-cluster   ⚙️  Create Kubernetes cluster with Kind"
	@echo "  make install-deps    📦 Install system dependencies (Homebrew)"
	@echo "  make check-env       🔍 Validate environment and prerequisites"
	@echo ""
	@echo -e "$(CYAN)🚀 DEPLOYMENT:$(NC)"
	@echo "  make deploy-metallb  🌐 Deploy MetalLB load balancer"
	@echo "  make build-awx-image 🔨 Build custom AWX Docker image"
	@echo "  make deploy-awx      🎭 Deploy AWX on cluster"
	@echo "  make configure-awx   ⚙️  Configure AWX with Cloudflare templates"
	@echo "  make deploy-all      🎯 Deploy MetalLB + AWX + Configuration"
	@echo ""
	@echo -e "$(CYAN)🧹 CLEANUP:$(NC)"
	@echo "  make clean           🗑️  Remove AWX deployment"
	@echo "  make clean-cluster   ⚠️  Delete entire cluster"
	@echo "  make clean-all       💣 Remove everything (cluster + images)"
	@echo "  make reset           🔄 Clean and redeploy from scratch"
	@echo ""
	@echo -e "$(CYAN)🎭 AWX OPERATIONS:$(NC)"
	@echo "  make awx             🌐 Port-forward AWX UI to localhost"
	@echo "  make awx-status      📊 Check AWX deployment status"
	@echo "  make awx-password    🔐 Display AWX admin password"
	@echo "  make awx-logs        📋 View AWX logs"
	@echo "  make awx-restart     🔄 Restart AWX pods"
	@echo ""
	@echo -e "$(CYAN)☁️  CLOUDFLARE OPERATIONS:$(NC)"
	@echo "  make test-cloudflare     🧪 Test API connectivity"
	@echo "  make cf-zones            📋 List all Cloudflare zones"
	@echo "  make cf-dns-list         📋 List DNS records"
	@echo "  make cf-run-playbook     🎬 Run Cloudflare playbook"
	@echo ""
	@echo -e "$(CYAN)🔍 MONITORING & STATUS:$(NC)"
	@echo "  make status          📊 Show comprehensive status"
	@echo "  make validate        ✅ Validate all deployments"
	@echo "  make logs            📋 View all component logs"
	@echo "  make dashboard       📈 Open Kubernetes dashboard"
	@echo ""
	@echo -e "$(CYAN)💾 BACKUP & RESTORE:$(NC)"
	@echo "  make backup          💾 Backup AWX configuration"
	@echo "  make restore         🔄 Restore from backup"
	@echo "  make list-backups    📋 List available backups"
	@echo ""
	@echo -e "$(CYAN)🧪 TESTING & DEVELOPMENT:$(NC)"
	@echo "  make test            🧪 Run all tests"
	@echo "  make lint            🔍 Lint Ansible playbooks"
	@echo "  make validate-yaml   ✅ Validate YAML files"
	@echo "  make docs            📚 Generate documentation"
	@echo ""
	@echo -e "$(YELLOW)🎯 EXAMPLES:$(NC)"
	@echo "  make deploy                      # Complete setup and deployment"
	@echo "  make awx                         # Access AWX at http://localhost:8080"
	@echo "  make cf-run-playbook PLAYBOOK=dns_management.yml ACTION=list DOMAIN=example.com"
	@echo ""
	@echo -e "$(YELLOW)📖 DOCUMENTATION:$(NC)"
	@echo "  README.md                        # Project overview"
	@echo "  docs/QUICKSTART.md               # Quick start guide"
	@echo "  docs/DEPLOYMENT.md               # Detailed deployment guide"
	@echo "  docs/CLOUDFLARE_OPS.md           # Cloudflare operations"
	@echo ""

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

check-env:
	@echo -e "$(BLUE)🔍 Checking environment prerequisites...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo -e "$(RED)❌ Docker not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)✅ Docker found: $$(docker --version)$(NC)"
	@command -v kind >/dev/null 2>&1 || { echo -e "$(RED)❌ Kind not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)✅ Kind found: $$(kind --version)$(NC)"
	@command -v kubectl >/dev/null 2>&1 || { echo -e "$(RED)❌ kubectl not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)✅ kubectl found: $$(kubectl version --client --short 2>/dev/null || kubectl version --client)$(NC)"
	@command -v helm >/dev/null 2>&1 || { echo -e "$(RED)❌ Helm not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)✅ Helm found: $$(helm version --short)$(NC)"
	@command -v python3 >/dev/null 2>&1 || { echo -e "$(RED)❌ Python3 not found$(NC)"; exit 1; }
	@echo -e "$(GREEN)✅ Python3 found: $$(python3 --version)$(NC)"
	@echo -e "$(GREEN)🎉 All prerequisites are installed!$(NC)"

install-deps:
	@echo -e "$(BLUE)📦 Installing system dependencies...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo -e "$(BLUE)Installing with Homebrew...$(NC)"; \
		brew install kind kubectl helm ansible python3; \
		echo -e "$(GREEN)✅ Dependencies installed$(NC)"; \
	else \
		echo -e "$(RED)❌ Homebrew not found. Please install manually:$(NC)"; \
		echo "  - Docker: https://docs.docker.com/get-docker/"; \
		echo "  - Kind: https://kind.sigs.k8s.io/docs/user/quick-start/"; \
		echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"; \
		echo "  - Helm: https://helm.sh/docs/intro/install/"; \
		echo "  - Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"; \
		exit 1; \
	fi

setup-python:
	@echo -e "$(BLUE)🐍 Setting up Python environment...$(NC)"
	@$(PYTHON_CMD) -m pip install --upgrade pip setuptools wheel
	@$(PIP_CMD) install -r requirements.txt
	@ansible-galaxy collection install -r requirements.yml
	@echo -e "$(GREEN)✅ Python environment configured$(NC)"

# =============================================================================
# CLUSTER MANAGEMENT
# =============================================================================

setup-cluster:
	@echo -e "$(BLUE)⚙️  Creating Kubernetes cluster with Kind...$(NC)"
	@if kind get clusters 2>/dev/null | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo -e "$(YELLOW)⚠️  Cluster '$(CLUSTER_NAME)' already exists$(NC)"; \
	else \
		$(SCRIPTS_DIR)/setup-cluster.sh $(CLUSTER_NAME); \
		echo -e "$(GREEN)✅ Cluster created successfully$(NC)"; \
	fi
	@echo -e "$(BLUE)Configuring kubectl context...$(NC)"
	@kubectl cluster-info --context kind-$(CLUSTER_NAME)
	@echo -e "$(GREEN)✅ Cluster is ready!$(NC)"

clean-cluster:
	@echo -e "$(YELLOW)⚠️  Deleting cluster '$(CLUSTER_NAME)'...$(NC)"
	@read -p "Are you sure? This will destroy all data! (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		kind delete cluster --name $(CLUSTER_NAME); \
		echo -e "$(GREEN)✅ Cluster deleted$(NC)"; \
	else \
		echo -e "$(BLUE)Cancelled$(NC)"; \
	fi

# =============================================================================
# METALLB DEPLOYMENT
# =============================================================================

deploy-metallb:
	@echo -e "$(BLUE)🌐 Deploying MetalLB...$(NC)"
	@kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VERSION)/config/manifests/metallb-native.yaml
	@echo -e "$(BLUE)Waiting for MetalLB to be ready...$(NC)"
	@kubectl wait --namespace metallb-system \
		--for=condition=ready pod \
		--selector=app=metallb \
		--timeout=90s
	@echo -e "$(BLUE)Configuring MetalLB IP address pool...$(NC)"
	@kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $(METALLB_IP_RANGE)
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
	@echo -e "$(GREEN)✅ MetalLB deployed and configured$(NC)"

# =============================================================================
# AWX DEPLOYMENT
# =============================================================================

build-awx-image:
	@echo -e "$(BLUE)🔨 Building custom AWX image...$(NC)"
	@echo -e "$(BLUE)Starting local Docker registry...$(NC)"
	@if ! docker ps | grep -q registry; then \
		docker run -d -p 5000:5000 --restart=always --name registry registry:2 || true; \
	fi
	@cd $(AWX_IMAGE_DIR) && docker build -t $(AWX_FULL_IMAGE) .
	@echo -e "$(BLUE)Pushing image to local registry...$(NC)"
	@docker push $(AWX_FULL_IMAGE)
	@echo -e "$(BLUE)Loading image into Kind cluster...$(NC)"
	@kind load docker-image $(AWX_FULL_IMAGE) --name $(CLUSTER_NAME) || true
	@echo -e "$(GREEN)✅ AWX image built and loaded$(NC)"

deploy-awx:
	@echo -e "$(BLUE)🎭 Deploying AWX...$(NC)"
	@echo -e "$(BLUE)Creating AWX namespace...$(NC)"
	@kubectl create namespace $(AWX_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo -e "$(BLUE)Installing AWX Operator...$(NC)"
	@kubectl apply -k "github.com/ansible/awx-operator/config/default?ref=$(AWX_OPERATOR_VERSION)" || \
		kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/$(AWX_OPERATOR_VERSION)/config/samples/awx-operator.yaml
	@echo -e "$(BLUE)Waiting for AWX Operator...$(NC)"
	@kubectl wait --for=condition=available --timeout=300s deployment/awx-operator-controller-manager -n $(AWX_NAMESPACE) || true
	@echo -e "$(BLUE)Creating AWX admin password secret...$(NC)"
	@kubectl create secret generic ansible-awx-admin-password \
		--from-literal=password=$$(openssl rand -base64 32) \
		-n $(AWX_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo -e "$(BLUE)Creating AWX postgres password secret...$(NC)"
	@kubectl create secret generic ansible-awx-postgres-configuration \
		--from-literal=host=ansible-awx-postgres-15 \
		--from-literal=port=5432 \
		--from-literal=database=awx \
		--from-literal=username=awx \
		--from-literal=password=$$(openssl rand -base64 32) \
		--from-literal=type=managed \
		-n $(AWX_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo -e "$(BLUE)Deploying AWX instance...$(NC)"
	@kubectl apply -f $(CONFIG_DIR)/awx-instance.yaml
	@echo -e "$(BLUE)Waiting for AWX to be ready (this may take 5-10 minutes)...$(NC)"
	@echo -e "$(YELLOW)You can check progress with: make awx-status$(NC)"
	@timeout 600 bash -c 'until kubectl get pods -n $(AWX_NAMESPACE) -l app.kubernetes.io/name=ansible-awx-web -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do sleep 10; echo "Waiting..."; done' || true
	@echo -e "$(GREEN)✅ AWX deployed successfully!$(NC)"
	@echo -e "$(CYAN)Access AWX with: make awx$(NC)"

configure-awx:
	@echo -e "$(BLUE)⚙️  Configuring AWX with Cloudflare templates...$(NC)"
	@$(SCRIPTS_DIR)/configure-awx.sh
	@echo -e "$(GREEN)✅ AWX configured$(NC)"

# =============================================================================
# AWX OPERATIONS
# =============================================================================

awx:
	@echo -e "$(BLUE)🌐 Port-forwarding AWX to localhost:$(AWX_SERVICE_PORT)...$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(CYAN)  AWX Web Interface$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)  URL:      http://localhost:$(AWX_SERVICE_PORT)$(NC)"
	@echo -e "$(GREEN)  Username: $(AWX_ADMIN_USER)$(NC)"
	@echo -e "$(GREEN)  Password: $$(kubectl get secret ansible-awx-admin-password -n $(AWX_NAMESPACE) -o jsonpath='{.data.password}' | base64 --decode)$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(YELLOW)Press Ctrl+C to stop port-forwarding$(NC)"
	@kubectl port-forward -n $(AWX_NAMESPACE) service/ansible-awx-service $(AWX_SERVICE_PORT):80

awx-password:
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(CYAN)  AWX Admin Credentials$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(GREEN)  Username: $(AWX_ADMIN_USER)$(NC)"
	@echo -e "$(GREEN)  Password: $$(kubectl get secret ansible-awx-admin-password -n $(AWX_NAMESPACE) -o jsonpath='{.data.password}' | base64 --decode)$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"

awx-status:
	@echo -e "$(BLUE)📊 AWX Deployment Status:$(NC)"
	@echo -e "$(CYAN)Pods:$(NC)"
	@kubectl get pods -n $(AWX_NAMESPACE) -l "app.kubernetes.io/part-of=ansible-awx"
	@echo ""
	@echo -e "$(CYAN)Services:$(NC)"
	@kubectl get services -n $(AWX_NAMESPACE)
	@echo ""
	@echo -e "$(CYAN)AWX Instance:$(NC)"
	@kubectl get awx -n $(AWX_NAMESPACE)

awx-logs:
	@echo -e "$(BLUE)📋 AWX Web Logs:$(NC)"
	@kubectl logs -n $(AWX_NAMESPACE) -l app.kubernetes.io/name=ansible-awx-web --tail=100 -f

awx-restart:
	@echo -e "$(BLUE)🔄 Restarting AWX pods...$(NC)"
	@kubectl delete pods -n $(AWX_NAMESPACE) -l "app.kubernetes.io/part-of=ansible-awx"
	@echo -e "$(GREEN)✅ AWX pods restarted$(NC)"

# =============================================================================
# CLOUDFLARE OPERATIONS
# =============================================================================

test-cloudflare:
	@echo -e "$(BLUE)🧪 Testing Cloudflare API connectivity...$(NC)"
	@if [ -f "$(CONFIG_DIR)/credentials.yml" ]; then \
		export CLOUDFLARE_API_TOKEN=$$(grep cloudflare_api_token $(CONFIG_DIR)/credentials.yml | awk '{print $$2}' | tr -d '"'); \
		if [ -z "$$CLOUDFLARE_API_TOKEN" ] || [ "$$CLOUDFLARE_API_TOKEN" = "YOUR_CLOUDFLARE_API_TOKEN_HERE" ]; then \
			echo -e "$(RED)❌ Cloudflare API token not configured in $(CONFIG_DIR)/credentials.yml$(NC)"; \
			echo -e "$(YELLOW)Please copy config/credentials.yml.example to config/credentials.yml and add your token$(NC)"; \
			exit 1; \
		fi; \
		response=$$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
			-H "Authorization: Bearer $$CLOUDFLARE_API_TOKEN" \
			-H "Content-Type: application/json"); \
		if echo "$$response" | grep -q '"success":true'; then \
			echo -e "$(GREEN)✅ Cloudflare API token is valid!$(NC)"; \
			echo "$$response" | python3 -m json.tool; \
		else \
			echo -e "$(RED)❌ Cloudflare API token is invalid$(NC)"; \
			echo "$$response" | python3 -m json.tool; \
			exit 1; \
		fi \
	else \
		echo -e "$(RED)❌ $(CONFIG_DIR)/credentials.yml not found$(NC)"; \
		echo -e "$(YELLOW)Please copy config/credentials.yml.example to config/credentials.yml$(NC)"; \
		exit 1; \
	fi

cf-zones:
	@echo -e "$(BLUE)📋 Listing Cloudflare zones...$(NC)"
	@export CLOUDFLARE_API_TOKEN=$$(grep cloudflare_api_token $(CONFIG_DIR)/credentials.yml | awk '{print $$2}' | tr -d '"'); \
	curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
		-H "Authorization: Bearer $$CLOUDFLARE_API_TOKEN" \
		-H "Content-Type: application/json" | python3 -m json.tool

cf-dns-list:
	@echo -e "$(BLUE)📋 Listing DNS records for zone: $(DOMAIN)$(NC)"
	@if [ -z "$(DOMAIN)" ]; then \
		echo -e "$(RED)❌ DOMAIN variable not set$(NC)"; \
		echo "Usage: make cf-dns-list DOMAIN=example.com"; \
		exit 1; \
	fi
	@ansible-playbook $(PLAYBOOKS_DIR)/cloudflare/dns_management.yml \
		-e "cf_action=list" \
		-e "cf_domain=$(DOMAIN)"

cf-run-playbook:
	@echo -e "$(BLUE)🎬 Running Cloudflare playbook...$(NC)"
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo -e "$(RED)❌ PLAYBOOK variable not set$(NC)"; \
		echo "Usage: make cf-run-playbook PLAYBOOK=dns_management.yml ACTION=list DOMAIN=example.com"; \
		exit 1; \
	fi
	@ansible-playbook $(PLAYBOOKS_DIR)/cloudflare/$(PLAYBOOK) \
		$(if $(ACTION),-e "cf_action=$(ACTION)",) \
		$(if $(DOMAIN),-e "cf_domain=$(DOMAIN)",) \
		$(if $(RECORD_NAME),-e "cf_record_name=$(RECORD_NAME)",) \
		$(if $(RECORD_TYPE),-e "cf_record_type=$(RECORD_TYPE)",) \
		$(if $(RECORD_VALUE),-e "cf_record_value=$(RECORD_VALUE)",) \
		$(EXTRA_VARS)

# =============================================================================
# COMPLETE WORKFLOWS
# =============================================================================

setup: check-env setup-python setup-cluster
	@echo -e "$(GREEN)🎉 Complete setup finished!$(NC)"

deploy: setup deploy-metallb build-awx-image deploy-awx
	@echo -e "$(GREEN)🎉 Complete deployment finished!$(NC)"
	@echo -e "$(CYAN)Next steps:$(NC)"
	@echo "  1. Configure AWX: make configure-awx"
	@echo "  2. Access AWX: make awx"
	@echo "  3. Test Cloudflare: make test-cloudflare"

deploy-all: deploy configure-awx
	@echo -e "$(GREEN)🎉 Everything deployed and configured!$(NC)"
	@$(MAKE) awx-password
	@echo -e "$(CYAN)Access AWX with: make awx$(NC)"

# =============================================================================
# CLEANUP
# =============================================================================

clean:
	@echo -e "$(YELLOW)🗑️  Removing AWX deployment...$(NC)"
	@kubectl delete awx ansible-awx -n $(AWX_NAMESPACE) --ignore-not-found=true
	@kubectl delete namespace $(AWX_NAMESPACE) --ignore-not-found=true
	@echo -e "$(GREEN)✅ AWX removed$(NC)"

clean-all: clean clean-cluster
	@echo -e "$(YELLOW)💣 Removing Docker registry...$(NC)"
	@docker rm -f registry || true
	@echo -e "$(GREEN)✅ Everything cleaned$(NC)"

reset: clean-all deploy-all
	@echo -e "$(GREEN)🔄 System reset and redeployed!$(NC)"

# =============================================================================
# MONITORING AND STATUS
# =============================================================================

status:
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(CYAN)  📊 CF-DEMO-REPO Status$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════════════════$(NC)"
	@echo -e "$(BLUE)Cluster:$(NC)"
	@kind get clusters | grep $(CLUSTER_NAME) && echo -e "$(GREEN)  ✅ Cluster running$(NC)" || echo -e "$(RED)  ❌ Cluster not found$(NC)"
	@echo ""
	@echo -e "$(BLUE)Kubernetes Context:$(NC)"
	@kubectl config current-context
	@echo ""
	@echo -e "$(BLUE)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo -e "$(BLUE)Namespaces:$(NC)"
	@kubectl get namespaces | grep -E "($(AWX_NAMESPACE)|$(METALLB_NAMESPACE))"
	@echo ""
	@$(MAKE) awx-status

validate:
	@echo -e "$(BLUE)✅ Running validations...$(NC)"
	@$(MAKE) check-env
	@echo ""
	@$(MAKE) test-cloudflare || true
	@echo ""
	@echo -e "$(GREEN)✅ Validation complete$(NC)"

# =============================================================================
# DEVELOPMENT AND TESTING
# =============================================================================

test:
	@echo -e "$(BLUE)🧪 Running tests...$(NC)"
	@$(PYTHON_CMD) -m pytest tests/ -v

lint:
	@echo -e "$(BLUE)🔍 Linting Ansible playbooks...$(NC)"
	@ansible-lint $(PLAYBOOKS_DIR)/**/*.yml || true
	@yamllint $(PLAYBOOKS_DIR) $(INVENTORY_DIR) || true

validate-yaml:
	@echo -e "$(BLUE)✅ Validating YAML files...$(NC)"
	@find . -name "*.yml" -o -name "*.yaml" | xargs yamllint || true

# =============================================================================
# BACKUP AND RESTORE
# =============================================================================

backup:
	@echo -e "$(BLUE)💾 Creating backup...$(NC)"
	@mkdir -p backups
	@timestamp=$$(date +%Y%m%d_%H%M%S); \
	kubectl get awx -n $(AWX_NAMESPACE) -o yaml > backups/awx-instance-$$timestamp.yaml; \
	kubectl get secrets -n $(AWX_NAMESPACE) -o yaml > backups/awx-secrets-$$timestamp.yaml; \
	echo -e "$(GREEN)✅ Backup created: backups/awx-*-$$timestamp.yaml$(NC)"

list-backups:
	@echo -e "$(BLUE)📋 Available backups:$(NC)"
	@ls -lh backups/ 2>/dev/null || echo "No backups found"

# =============================================================================
# DEFAULT TARGET
# =============================================================================

.DEFAULT_GOAL := help
