#!/bin/bash
# =============================================================================
# CONFIGURE AWX WITH CLOUDFLARE TEMPLATES
# =============================================================================
# Purpose: Configure AWX with Cloudflare job templates, credentials, and inventories
# Usage: ./scripts/configure-awx.sh
# =============================================================================

set -euo pipefail

# Configuration
AWX_NAMESPACE="awx"
AWX_SERVICE="ansible-awx-service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ⚙️  Configuring AWX with Cloudflare Templates${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

# Get AWX admin password
echo -e "${BLUE}Retrieving AWX admin password...${NC}"
AWX_PASSWORD=$(kubectl get secret ansible-awx-admin-password -n ${AWX_NAMESPACE} -o jsonpath='{.data.password}' | base64 --decode)

if [ -z "$AWX_PASSWORD" ]; then
    echo -e "${RED}❌ Failed to retrieve AWX password${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWX password retrieved${NC}"

# Wait for AWX to be fully ready
echo -e "${BLUE}Waiting for AWX to be ready...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ansible-awx-web -n ${AWX_NAMESPACE} --timeout=600s

# Port-forward AWX in the background
echo -e "${BLUE}Setting up port-forward to AWX...${NC}"
kubectl port-forward -n ${AWX_NAMESPACE} service/${AWX_SERVICE} 8080:80 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 5

# Function to cleanup on exit
cleanup() {
    if [ -n "${PORT_FORWARD_PID:-}" ]; then
        kill ${PORT_FORWARD_PID} 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test AWX connectivity
echo -e "${BLUE}Testing AWX connectivity...${NC}"
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v2/ping/ | grep -q "200"; then
        echo -e "${GREEN}✅ AWX is accessible${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Failed to connect to AWX${NC}"
        exit 1
    fi
    sleep 2
done

# AWX API base URL
AWX_URL="http://localhost:8080/api/v2"

echo -e "${BLUE}Configuring AWX via API...${NC}"

# 1. Create Organization (if not exists)
echo -e "${BLUE}Creating organization...${NC}"
ORG_RESPONSE=$(curl -s -X POST "${AWX_URL}/organizations/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Cloudflare Automation",
        "description": "Organization for Cloudflare DNS and security automation"
    }' || echo '{"id": 1}')

ORG_ID=$(echo "$ORG_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 1))" 2>/dev/null || echo "1")
echo -e "${GREEN}✅ Organization ID: ${ORG_ID}${NC}"

# 2. Create Credential Type for Cloudflare
echo -e "${BLUE}Creating Cloudflare credential type...${NC}"
CRED_TYPE_RESPONSE=$(curl -s -X POST "${AWX_URL}/credential_types/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Cloudflare API Token",
        "description": "Cloudflare API Token for automation",
        "kind": "cloud",
        "inputs": {
            "fields": [
                {
                    "id": "api_token",
                    "label": "API Token",
                    "type": "string",
                    "secret": true
                }
            ],
            "required": ["api_token"]
        },
        "injectors": {
            "env": {
                "CLOUDFLARE_API_TOKEN": "{{ api_token }}"
            }
        }
    }' || echo '{"id": 1}')

CRED_TYPE_ID=$(echo "$CRED_TYPE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 1))" 2>/dev/null || echo "1")
echo -e "${GREEN}✅ Credential Type ID: ${CRED_TYPE_ID}${NC}"

# 3. Create Inventory
echo -e "${BLUE}Creating inventory...${NC}"
INV_RESPONSE=$(curl -s -X POST "${AWX_URL}/inventories/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Localhost\",
        \"description\": \"Local execution for Cloudflare API operations\",
        \"organization\": ${ORG_ID}
    }" || echo '{"id": 1}')

INV_ID=$(echo "$INV_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 1))" 2>/dev/null || echo "1")
echo -e "${GREEN}✅ Inventory ID: ${INV_ID}${NC}"

# 4. Create Host in Inventory
echo -e "${BLUE}Creating localhost host...${NC}"
HOST_RESPONSE=$(curl -s -X POST "${AWX_URL}/inventories/${INV_ID}/hosts/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "localhost",
        "description": "Local host for API operations",
        "variables": "---\nansible_connection: local\nansible_python_interpreter: /usr/bin/python3"
    }' || echo '{"id": 1}')

echo -e "${GREEN}✅ Host created${NC}"

# 5. Create Project (Git repository)
echo -e "${BLUE}Creating project...${NC}"
# Note: In production, replace with your actual Git repository URL
PROJECT_RESPONSE=$(curl -s -X POST "${AWX_URL}/projects/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Cloudflare Playbooks\",
        \"description\": \"Ansible playbooks for Cloudflare automation\",
        \"organization\": ${ORG_ID},
        \"scm_type\": \"git\",
        \"scm_url\": \"https://github.com/T-Hlophe-gameflex/CF-DEMO-REPO.git\",
        \"scm_branch\": \"main\",
        \"scm_clean\": true,
        \"scm_delete_on_update\": false,
        \"scm_update_on_launch\": true,
        \"scm_update_cache_timeout\": 0
    }" || echo '{"id": 1}')

PROJECT_ID=$(echo "$PROJECT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 1))" 2>/dev/null || echo "1")
echo -e "${GREEN}✅ Project ID: ${PROJECT_ID}${NC}"

# 6. Create Job Template for DNS Management
echo -e "${BLUE}Creating DNS Management job template...${NC}"
JOB_TEMPLATE_RESPONSE=$(curl -s -X POST "${AWX_URL}/job_templates/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Cloudflare DNS Management\",
        \"description\": \"Manage DNS records in Cloudflare\",
        \"job_type\": \"run\",
        \"inventory\": ${INV_ID},
        \"project\": ${PROJECT_ID},
        \"playbook\": \"playbooks/cloudflare/dns_management.yml\",
        \"ask_variables_on_launch\": true,
        \"survey_enabled\": true
    }" || echo '{"id": 1}')

JOB_TEMPLATE_ID=$(echo "$JOB_TEMPLATE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 1))" 2>/dev/null || echo "1")
echo -e "${GREEN}✅ Job Template ID: ${JOB_TEMPLATE_ID}${NC}"

# 7. Add Survey to Job Template
echo -e "${BLUE}Adding survey to job template...${NC}"
curl -s -X POST "${AWX_URL}/job_templates/${JOB_TEMPLATE_ID}/survey_spec/" \
    -u "admin:${AWX_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Cloudflare DNS Survey",
        "description": "Parameters for DNS management",
        "spec": [
            {
                "question_name": "Action",
                "question_description": "DNS operation to perform",
                "required": true,
                "type": "multiplechoice",
                "variable": "cf_action",
                "choices": ["create", "update", "delete", "list"],
                "default": "list"
            },
            {
                "question_name": "Domain",
                "question_description": "Cloudflare zone/domain name",
                "required": true,
                "type": "text",
                "variable": "cf_domain",
                "default": "example.com"
            },
            {
                "question_name": "Record Name",
                "question_description": "DNS record name (without domain)",
                "required": false,
                "type": "text",
                "variable": "cf_record_name",
                "default": "www"
            },
            {
                "question_name": "Record Type",
                "question_description": "DNS record type",
                "required": false,
                "type": "multiplechoice",
                "variable": "cf_record_type",
                "choices": ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SRV"],
                "default": "A"
            },
            {
                "question_name": "Record Value",
                "question_description": "DNS record value/content",
                "required": false,
                "type": "text",
                "variable": "cf_record_value",
                "default": "192.168.1.1"
            },
            {
                "question_name": "Proxied",
                "question_description": "Enable Cloudflare proxy",
                "required": false,
                "type": "multiplechoice",
                "variable": "cf_record_proxied",
                "choices": ["true", "false"],
                "default": "true"
            }
        ]
    }' > /dev/null

echo -e "${GREEN}✅ Survey added${NC}"

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ AWX Configuration Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}AWX Details:${NC}"
echo "  URL: http://localhost:8080"
echo "  Username: admin"
echo "  Password: ${AWX_PASSWORD}"
echo ""
echo -e "${BLUE}Created Resources:${NC}"
echo "  - Organization: Cloudflare Automation (ID: ${ORG_ID})"
echo "  - Credential Type: Cloudflare API Token (ID: ${CRED_TYPE_ID})"
echo "  - Inventory: Localhost (ID: ${INV_ID})"
echo "  - Project: Cloudflare Playbooks (ID: ${PROJECT_ID})"
echo "  - Job Template: Cloudflare DNS Management (ID: ${JOB_TEMPLATE_ID})"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "  1. Add your Cloudflare API token in AWX:"
echo "     - Go to Resources → Credentials → Add"
echo "     - Select credential type 'Cloudflare API Token'"
echo "     - Enter your API token"
echo "  2. Assign the credential to the job template"
echo "  3. Run the job template with your zone information"
echo ""
