#!/bin/bash
set -e

echo "🔧 Setting up local Git repository for ArgoCD..."

# Initialize git if not already done
if [ ! -d .git ]; then
    echo "📦 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: ArgoCD local setup with Helm guestbook"
    echo "✅ Git repository initialized"
else
    echo "ℹ️  Git repository already exists"
fi

# Get the absolute path
REPO_PATH=$(pwd)

echo ""
echo "📝 Configuring ArgoCD to use local repository..."

# Update the guestbook application to use local Git repo
cat > argocd/applications/guestbook-local.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  source:
    repoURL: file://${REPO_PATH}
    targetRevision: HEAD
    path: helm-charts/guestbook
    helm:
      releaseName: guestbook
      valueFiles:
        - values.yaml
  
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

echo "✅ Created guestbook-local.yaml with local repository path"
echo ""
echo "📝 Note: ArgoCD needs to access the local repository."
echo "   For Kind clusters, we need to mount the local directory into the ArgoCD repo-server pod."
echo ""
echo "🚀 Deploying application..."

# Create namespace
kubectl create namespace guestbook --dry-run=client -o yaml | kubectl apply -f -

# Apply the application
kubectl apply -f argocd/applications/guestbook-local.yaml

echo ""
echo "✅ Application deployed!"
echo ""
echo "📊 Check status with:"
echo "   kubectl get application guestbook -n argocd"
echo "   kubectl get pods -n guestbook"
echo ""
echo "⚠️  Important: If using file:// URLs with Kind clusters, you may need to:"
echo "   1. Copy the Helm charts into the ArgoCD repo-server pod, OR"
echo "   2. Use a Git server (like Gitea) running in the cluster, OR"
echo "   3. Push to a remote Git repository (GitHub, GitLab, etc.)"
