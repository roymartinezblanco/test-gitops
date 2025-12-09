#!/bin/bash
set -e

echo "🚀 Creating Kind cluster for ArgoCD..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed. Please install it first."
    exit 1
fi

# Check if cluster already exists
if kind get clusters | grep -q "argocd-local"; then
    echo "⚠️  Cluster 'argocd-local' already exists."
    read -p "Do you want to delete it and create a new one? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name argocd-local
    else
        echo "✅ Using existing cluster."
        exit 0
    fi
fi

# Create the cluster
echo "📦 Creating cluster with configuration..."
kind create cluster --config kind-config.yaml

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "✅ Kind cluster created successfully!"
echo "📊 Cluster info:"
kubectl cluster-info --context kind-argocd-local

echo ""
echo "Next steps:"
echo "  1. Run './scripts/install-argocd.sh' to install ArgoCD"
echo "  2. Run './scripts/deploy-guestbook.sh' to deploy the guestbook app"
