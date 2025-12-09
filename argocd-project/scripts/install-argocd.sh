#!/bin/bash
set -e

echo "🚀 Installing ArgoCD..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Create argocd namespace
echo "📦 Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "⬇️  Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Get the initial password
echo ""
echo "✅ ArgoCD installed successfully!"
echo ""
echo "📝 ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "🌐 To access ArgoCD UI:"
echo "   1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   2. Open: https://localhost:8080"
echo "   3. Username: admin"
echo "   4. Password: (shown above)"
echo ""
echo "💡 Tip: You can also install the ArgoCD CLI for easier management:"
echo "   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo ""
echo "Next step:"
echo "  Run './scripts/deploy-guestbook.sh' to deploy the guestbook application"
