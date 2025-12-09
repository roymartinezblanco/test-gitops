# Quick Reference Guide

## Quick Start (3 commands)

```bash
# 1. Create everything at once
make deploy-all

# 2. Access ArgoCD
make port-forward-argocd  # https://localhost:8080

# 3. Access Guestbook
make port-forward-guestbook  # http://localhost:8081
```

## Common Commands

### Cluster Management
```bash
make create-cluster        # Create Kind cluster
make cleanup              # Delete Kind cluster
make status               # View all resources
```

### ArgoCD
```bash
make install-argocd       # Install ArgoCD
make argocd-password      # Get admin password
make port-forward-argocd  # Access UI at https://localhost:8080
make logs-argocd          # View ArgoCD logs
```

### Guestbook Application
```bash
make deploy-guestbook          # Deploy guestbook
make port-forward-guestbook    # Access UI at http://localhost:8081
make logs-guestbook           # View guestbook logs
make helm-template            # Preview rendered templates
```

### Helm Operations
```bash
make helm-install         # Install with Helm directly
make helm-uninstall      # Uninstall Helm release
helm list -n guestbook   # List Helm releases
```

### ArgoCD Operations
```bash
make argocd-sync         # Force sync application
make argocd-refresh      # Refresh application state
make describe-app        # Describe application
make get-app            # Get application YAML
```

## Kubectl Shortcuts

### View Resources
```bash
kubectl get all -n guestbook                    # All guestbook resources
kubectl get applications -n argocd              # ArgoCD applications
kubectl get pods -n argocd                      # ArgoCD pods
kubectl get pods -n guestbook -w               # Watch guestbook pods
```

### Logs
```bash
kubectl logs -n guestbook -l app=guestbook -f  # Follow guestbook logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f  # ArgoCD logs
```

### Debugging
```bash
kubectl describe pod <pod-name> -n guestbook   # Pod details
kubectl exec -it <pod-name> -n guestbook -- sh # Shell into pod
kubectl get events -n guestbook --sort-by='.lastTimestamp'  # Recent events
```

## ArgoCD CLI (Optional)

### Installation
```bash
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd /usr/local/bin/argocd
```

### Usage
```bash
# Login
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
argocd login localhost:8080

# Application operations
argocd app list                           # List applications
argocd app get guestbook                  # Get application details
argocd app sync guestbook                 # Sync application
argocd app history guestbook              # View sync history
argocd app rollback guestbook             # Rollback to previous version
argocd app delete guestbook               # Delete application
```

## Helm Values Override

### Method 1: Edit values.yaml
```bash
# Edit the file
vim helm-charts/guestbook/values.yaml

# Update in cluster
helm upgrade guestbook ./helm-charts/guestbook -n guestbook
```

### Method 2: Command-line override
```bash
helm upgrade guestbook ./helm-charts/guestbook -n guestbook \
  --set replicaCount=3 \
  --set image.tag=0.3
```

### Method 3: Separate values file
```bash
# Create values-prod.yaml
cat > values-prod.yaml <<EOF
replicaCount: 3
resources:
  limits:
    memory: 512Mi
EOF

# Install with override
helm upgrade guestbook ./helm-charts/guestbook -n guestbook \
  -f values-prod.yaml
```

## GitOps Workflow

### Option A: Direct Helm (Current Setup)
1. Make changes to `helm-charts/guestbook/`
2. Run `helm upgrade guestbook ./helm-charts/guestbook -n guestbook`

### Option B: Git-based ArgoCD
1. Push helm-charts to Git repository
2. Update `argocd/applications/guestbook-git.yaml` with repo URL
3. Apply: `kubectl apply -f argocd/applications/guestbook-git.yaml`
4. ArgoCD auto-syncs on Git changes

### Option C: In-cluster Gitea
1. Run `make setup-gitea`
2. Port forward: `kubectl port-forward svc/gitea -n gitea 3000:3000`
3. Create repository in Gitea
4. Push helm-charts to Gitea
5. Configure ArgoCD to use Gitea URL

## Troubleshooting

### Guestbook not accessible
```bash
# Check pods
kubectl get pods -n guestbook

# Check service
kubectl get svc -n guestbook

# Check logs
kubectl logs -n guestbook -l app=guestbook --tail=50

# Describe failing pod
kubectl describe pod <pod-name> -n guestbook
```

### ArgoCD application stuck syncing
```bash
# Check application status
kubectl get application guestbook -n argocd

# View detailed status
kubectl describe application guestbook -n argocd

# Check repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server

# Force refresh
make argocd-refresh
```

### Helm template errors
```bash
# Validate chart
helm lint ./helm-charts/guestbook

# Dry-run install
helm install guestbook ./helm-charts/guestbook -n guestbook --dry-run --debug

# Render templates
helm template guestbook ./helm-charts/guestbook
```

### Kind cluster issues
```bash
# Check cluster
kind get clusters

# Check nodes
kubectl get nodes

# Recreate cluster
make cleanup
make create-cluster
```

## Environment Variables

### Customize Ports
```bash
# ArgoCD UI (default: 8080)
kubectl port-forward svc/argocd-server -n argocd 9090:443

# Guestbook (default: 8081)
kubectl port-forward svc/guestbook-guestbook-ui -n guestbook 9091:80
```

## File Structure Reference
```
.
├── Makefile                       # Command shortcuts
├── README.md                      # Main documentation
├── HELM_VS_MANIFESTS.md          # Helm explanation
├── QUICKSTART.md                 # This file
├── kind-config.yaml              # Kind cluster config
├── scripts/
│   ├── create-cluster.sh         # Create Kind cluster
│   ├── install-argocd.sh         # Install ArgoCD
│   ├── deploy-guestbook.sh       # Deploy app
│   ├── deploy-all.sh             # All-in-one script
│   ├── setup-gitea.sh            # Local Git server
│   └── cleanup.sh                # Cleanup script
├── helm-charts/
│   └── guestbook/                # Helm chart
│       ├── Chart.yaml            # Chart metadata
│       ├── values.yaml           # Default values
│       └── templates/            # K8s templates
└── argocd/
    └── applications/
        ├── guestbook.yaml        # ArgoCD app (local)
        └── guestbook-git.yaml    # ArgoCD app (Git)
```

## Next Steps

1. ✅ **Explore ArgoCD UI** - See your application status
2. ✅ **Modify values.yaml** - Change replica count, resources, etc.
3. ✅ **Add more apps** - Create additional Helm charts
4. ✅ **Setup Git sync** - Connect to a real Git repository
5. ✅ **Learn Helm** - Understand templating and functions

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
