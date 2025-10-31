#!/bin/bash
# =============================================================================
# SETUP KUBERNETES CLUSTER WITH KIND
# =============================================================================
# Purpose: Create a Kind Kubernetes cluster with custom configuration
# Usage: ./scripts/setup-cluster.sh [cluster-name]
# =============================================================================

set -euo pipefail

# Configuration
CLUSTER_NAME="${1:-cf-demo-cluster}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🚀 Setting up Kubernetes Cluster with Kind${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}⚠️  Cluster '${CLUSTER_NAME}' already exists!${NC}"
    read -p "Do you want to delete and recreate it? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${BLUE}Deleting existing cluster...${NC}"
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo -e "${BLUE}Using existing cluster${NC}"
        exit 0
    fi
fi

# Create Kind cluster configuration
echo -e "${BLUE}Creating cluster configuration...${NC}"
cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 65402
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
      endpoint = ["http://registry:5000"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."localhost:5000".tls]
      insecure_skip_verify = true
EOF

# Create the cluster
echo -e "${BLUE}Creating Kind cluster '${CLUSTER_NAME}'...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
kind create cluster --config /tmp/kind-config.yaml

# Wait for cluster to be ready
echo -e "${BLUE}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Verify cluster
echo -e "${BLUE}Verifying cluster...${NC}"
kubectl cluster-info
kubectl get nodes

# Create local Docker registry (if not exists)
echo -e "${BLUE}Setting up local Docker registry...${NC}"
if ! docker ps | grep -q registry; then
    docker run -d -p 5000:5000 --restart=always --name registry registry:2 || true
fi

# Connect registry to Kind network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' registry 2>/dev/null)" = 'null' ]; then
    docker network connect kind registry || true
fi

# Create configmap for registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Cluster '${CLUSTER_NAME}' created successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Cluster Information:${NC}"
echo "  Name: ${CLUSTER_NAME}"
echo "  Context: kind-${CLUSTER_NAME}"
echo "  API Server: $(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Deploy MetalLB: make deploy-metallb"
echo "  2. Build AWX image: make build-awx-image"
echo "  3. Deploy AWX: make deploy-awx"
echo ""

# Cleanup
rm -f /tmp/kind-config.yaml
