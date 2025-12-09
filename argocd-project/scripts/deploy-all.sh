#!/bin/bash
set -e

echo "🚀 Complete ArgoCD Setup with Helm Guestbook"
echo "=============================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..."
MISSING_TOOLS=()

if ! command_exists kind; then
    MISSING_TOOLS+=("kind")
fi

if ! command_exists kubectl; then
    MISSING_TOOLS+=("kubectl")
fi

if ! command_exists helm; then
    MISSING_TOOLS+=("helm")
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "❌ Missing required tools: ${MISSING_TOOLS[*]}"
    echo ""
    echo "Please install them first:"
    echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  - helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ All prerequisites met!"
echo ""

# Step 1: Create cluster
echo "Step 1/4: Creating Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "argocd-local"; then
    echo "⚠️  Cluster 'argocd-local' already exists. Using existing cluster."
else
    ./scripts/create-cluster.sh
fi
echo ""

# Step 2: Install ArgoCD
echo "Step 2/4: Installing ArgoCD..."
if kubectl get namespace argocd &>/dev/null; then
    echo "⚠️  ArgoCD namespace already exists. Skipping installation."
else
    ./scripts/install-argocd.sh
fi
echo ""

# Step 3: Deploy using Helm
echo "Step 3/4: Deploying Guestbook with Helm..."
echo "📦 Installing Guestbook using Helm..."

helm upgrade --install guestbook ./helm-charts/guestbook \
    --namespace guestbook \
    --create-namespace \
    --wait

echo "✅ Guestbook deployed!"
echo ""

# Step 4: Import to ArgoCD (optional)
echo "Step 4/4: Configuring ArgoCD tracking..."
echo ""
echo "📝 The application is now running. To track it with ArgoCD, you have options:"
echo ""
echo "Option A: Track the Helm release (Recommended for local development)"
echo "   ArgoCD can track existing Helm releases"
echo ""
echo "Option B: Use a Git repository"
echo "   1. Push this project to a Git repository (GitHub, GitLab, etc.)"
echo "   2. Update argocd/applications/guestbook.yaml with your repo URL"
echo "   3. Run: kubectl apply -f argocd/applications/guestbook.yaml"
echo ""
echo "Option C: Use in-cluster Gitea"
echo "   Run: ./scripts/setup-gitea.sh"
echo ""

# Display status
echo "=============================================="
echo "✅ Setup Complete!"
echo "=============================================="
echo ""
echo "📊 Current Status:"
kubectl get pods -n guestbook
echo ""
kubectl get svc -n guestbook
echo ""
echo "🌐 Access Instructions:"
echo ""
echo "ArgoCD UI:"
echo "  1. Get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
echo "  2. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  3. Open: https://localhost:8080 (username: admin)"
echo ""
echo "Guestbook UI:"
echo "  1. Port forward: kubectl port-forward svc/guestbook-guestbook-ui -n guestbook 8081:80"
echo "  2. Open: http://localhost:8081"
echo ""
echo "📝 Useful Commands:"
echo "  - View all resources: kubectl get all -n guestbook"
echo "  - View ArgoCD apps: kubectl get applications -n argocd"
echo "  - View logs: kubectl logs -n guestbook -l app=guestbook"
echo "  - Cleanup: ./scripts/cleanup.sh"
echo ""
