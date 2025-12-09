#!/bin/bash
set -e

echo "🗑️  Cleaning up ArgoCD local environment..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed."
    exit 1
fi

# Check if cluster exists
if ! kind get clusters | grep -q "argocd-local"; then
    echo "ℹ️  Cluster 'argocd-local' does not exist. Nothing to clean up."
    exit 0
fi

echo "⚠️  This will delete the entire 'argocd-local' cluster and all its resources."
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

echo "🗑️  Deleting Kind cluster..."
kind delete cluster --name argocd-local

echo "✅ Cleanup complete!"
echo ""
echo "To recreate the environment, run:"
echo "  ./scripts/create-cluster.sh"
echo "  ./scripts/install-argocd.sh"
echo "  ./scripts/deploy-guestbook.sh"
