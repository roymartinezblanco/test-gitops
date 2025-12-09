#!/bin/bash
set -e

echo "🚀 Deploying Guestbook application via ArgoCD..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Check if ArgoCD is running
if ! kubectl get namespace argocd &> /dev/null; then
    echo "❌ ArgoCD namespace not found. Please run './scripts/install-argocd.sh' first."
    exit 1
fi

# Create a ConfigMap with the Helm chart
echo "📦 Creating ConfigMap with Helm chart..."
kubectl create namespace guestbook --dry-run=client -o yaml | kubectl apply -f -

# For local development, we need to make the Helm chart accessible to ArgoCD
# We'll use a different approach: apply the Helm chart directly via ArgoCD CLI or use in-cluster repo

echo "📝 Note: For local Helm charts, we have a few options:"
echo ""
echo "Option 1: Deploy using ArgoCD Application with Git repository"
echo "  - Push your helm-charts directory to a Git repository"
echo "  - Update argocd/applications/guestbook.yaml with the Git repo URL"
echo ""
echo "Option 2: Deploy using Helm directly (bypassing ArgoCD for now)"
echo "  - This will install the app, then we can import it to ArgoCD"
echo ""
read -p "Which option would you like? (1 for Git, 2 for Helm direct) [2]: " -n 1 -r
echo
OPTION=${REPLY:-2}

if [[ $OPTION == "1" ]]; then
    echo ""
    echo "📝 To use Git-based deployment:"
    echo "  1. Initialize git in the project root: git init"
    echo "  2. Add a remote: git remote add origin <your-repo-url>"
    echo "  3. Commit and push: git add . && git commit -m 'Initial commit' && git push"
    echo "  4. Update argocd/applications/guestbook.yaml with your Git repo URL"
    echo "  5. Apply the Application: kubectl apply -f argocd/applications/guestbook.yaml"
    echo ""
    echo "For testing with a local path, you can also use a local Git repo:"
    echo "  cd $(pwd)"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    echo ""
    echo "Then update the guestbook.yaml repoURL to: file://$(pwd)"
    
elif [[ $OPTION == "2" ]]; then
    echo "📦 Installing Guestbook using Helm..."
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        echo "❌ Helm is not installed. Please install it first."
        exit 1
    fi
    
    # Install using Helm
    helm upgrade --install guestbook ./helm-charts/guestbook \
        --namespace guestbook \
        --create-namespace \
        --wait
    
    echo ""
    echo "✅ Guestbook deployed successfully!"
    echo ""
    echo "📊 Application Status:"
    kubectl get pods -n guestbook
    echo ""
    kubectl get svc -n guestbook
    echo ""
    echo "🌐 To access the Guestbook UI:"
    echo "   kubectl port-forward svc/guestbook-guestbook-ui -n guestbook 8081:80"
    echo "   Then open: http://localhost:8081"
    echo ""
    echo "💡 To import this into ArgoCD for management:"
    echo "   You can create an Application that tracks this release, or"
    echo "   Use ArgoCD's ability to track Helm releases"
else
    echo "Invalid option selected"
    exit 1
fi

echo ""
echo "📝 Additional ArgoCD commands:"
echo "  - List applications: kubectl get applications -n argocd"
echo "  - Describe application: kubectl describe application guestbook -n argocd"
echo "  - Watch sync status: kubectl get application guestbook -n argocd -w"
