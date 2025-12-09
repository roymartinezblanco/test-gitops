# ArgoCD Local Development Project - Summary

## 📦 What's Included

This is a complete, production-ready setup for running ArgoCD locally with a Helm-based guestbook application.

### Key Components:

1. **Kind Cluster Configuration** (`kind-config.yaml`)
   - 3-node cluster (1 control-plane, 2 workers)
   - Port mappings for ingress

2. **Helm Chart** (`helm-charts/guestbook/`)
   - Complete guestbook application with Redis backend
   - Parameterized via values.yaml
   - Professional template structure with helpers

3. **ArgoCD Setup Scripts** (`scripts/`)
   - Automated cluster creation
   - ArgoCD installation
   - Application deployment
   - Complete cleanup

4. **ArgoCD Applications** (`argocd/applications/`)
   - Ready-to-use Application manifests
   - Support for both local and Git-based repos

5. **Documentation**
   - README.md - Main setup guide
   - QUICKSTART.md - Quick reference
   - HELM_VS_MANIFESTS.md - Detailed Helm explanation
   - This summary file

6. **Convenience Tools**
   - Makefile with common commands
   - Helper scripts for Gitea setup
   - .gitignore for clean Git repos

## 🎯 Main Differences from test-gitops

### 1. Uses Helm Instead of Plain Manifests
- **Parameterization**: Single values.yaml for all configuration
- **Templating**: Dynamic resource generation
- **Reusability**: Same chart for dev/staging/prod
- **Dependency Management**: Built-in support for chart dependencies

### 2. Professional Structure
- Follows Helm best practices
- Includes template helpers (_helpers.tpl)
- Proper resource naming with fullname functions
- Comprehensive labels and selectors

### 3. Complete Automation
- One-command deployment (`make deploy-all`)
- Automated ArgoCD installation
- Comprehensive cleanup scripts

### 4. Better Configuration Management
```yaml
# test-gitops style: Hardcoded values
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook
spec:
  replicas: 1  # <-- Hardcoded

# This project: Parameterized
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "guestbook.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}  # <-- From values.yaml
```

### 5. ArgoCD Repo Server Integration
- Automatic template rendering via repo-server
- Helm-specific sync policies
- Support for value overrides in ArgoCD

## 🚀 Quick Start

```bash
# Extract the archive
tar -xzf argocd-project.tar.gz
cd argocd-project

# Deploy everything
make deploy-all

# Access ArgoCD UI (in new terminal)
make port-forward-argocd
# Visit: https://localhost:8080
# Username: admin
# Password: Run 'make argocd-password'

# Access Guestbook UI (in new terminal)
make port-forward-guestbook
# Visit: http://localhost:8081
```

## 📋 Prerequisites

You need these tools installed:
- Docker (for Kind)
- kubectl
- kind
- helm
- make (optional, but recommended)

Installation links are in README.md.

## 🔄 Typical Workflow

### Local Development (Current Setup)
1. Edit `helm-charts/guestbook/values.yaml`
2. Run `helm upgrade guestbook ./helm-charts/guestbook -n guestbook`
3. Changes apply immediately

### GitOps Workflow (Recommended for Production)
1. Push helm-charts to Git repository
2. Update `argocd/applications/guestbook-git.yaml` with repo URL
3. Apply: `kubectl apply -f argocd/applications/guestbook-git.yaml`
4. ArgoCD auto-syncs on every Git push

## 📁 File Structure

```
argocd-project/
├── README.md                          # Main documentation
├── QUICKSTART.md                      # Quick reference guide
├── HELM_VS_MANIFESTS.md              # Detailed Helm explanation
├── Makefile                           # Convenient command shortcuts
├── kind-config.yaml                   # Kind cluster configuration
│
├── scripts/                           # Automation scripts
│   ├── create-cluster.sh             # Creates Kind cluster
│   ├── install-argocd.sh             # Installs ArgoCD
│   ├── deploy-guestbook.sh           # Deploys guestbook
│   ├── deploy-all.sh                 # Complete setup
│   ├── setup-gitea.sh                # Optional: in-cluster Git
│   ├── setup-local-repo.sh           # Optional: local Git setup
│   └── cleanup.sh                    # Cleanup everything
│
├── helm-charts/                       # Helm charts directory
│   └── guestbook/                    # Guestbook Helm chart
│       ├── Chart.yaml                # Chart metadata
│       ├── values.yaml               # Configuration values
│       └── templates/                # Kubernetes templates
│           ├── _helpers.tpl          # Template helpers
│           ├── deployment.yaml       # UI deployment
│           ├── service.yaml          # UI service
│           ├── redis-deployment.yaml # Redis deployment
│           └── redis-service.yaml    # Redis service
│
└── argocd/                           # ArgoCD configuration
    └── applications/                 # Application manifests
        ├── guestbook.yaml            # Local path version
        └── guestbook-git.yaml        # Git repo version
```

## 🎓 Learning Path

1. **Start Here**: Run `make deploy-all` and explore the UIs
2. **Understand Helm**: Read HELM_VS_MANIFESTS.md
3. **Modify Values**: Edit helm-charts/guestbook/values.yaml
4. **View Templates**: Run `make helm-template`
5. **Setup GitOps**: Connect to a real Git repository
6. **Scale Up**: Add more applications

## 🔧 Common Commands

All available in the Makefile:

```bash
make help                    # Show all commands
make deploy-all             # Complete setup
make status                 # Show resource status
make argocd-password        # Get ArgoCD password
make port-forward-argocd    # Access ArgoCD UI
make port-forward-guestbook # Access Guestbook UI
make logs-guestbook         # View app logs
make cleanup                # Delete everything
```

## 💡 Pro Tips

1. **Use the Makefile**: It simplifies common tasks
2. **Check logs**: If something fails, check logs with `make logs-*`
3. **Validate Helm**: Run `helm lint` before deploying
4. **Preview changes**: Use `helm template` to see rendered YAML
5. **Use Git**: Push to Git for true GitOps workflow

## 🐛 Troubleshooting

See QUICKSTART.md for detailed troubleshooting guide.

Quick checks:
```bash
make status                 # Overall status
kubectl get pods -A         # All pods
make logs-argocd           # ArgoCD logs
make logs-guestbook        # App logs
```

## 📚 Additional Resources

- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
- **Helm Docs**: https://helm.sh/docs/
- **Kind Docs**: https://kind.sigs.k8s.io/
- **Example Applications**: https://github.com/argoproj/argocd-example-apps

## 🎉 What's Next?

1. ✅ Explore the ArgoCD UI
2. ✅ Modify Helm values and see changes
3. ✅ Add your own Helm charts
4. ✅ Setup Git-based sync
5. ✅ Learn about Helm hooks and tests
6. ✅ Implement multi-environment setup

## 📧 Support

If you encounter issues:
1. Check QUICKSTART.md troubleshooting section
2. Review logs: `make logs-argocd` and `make logs-guestbook`
3. Verify prerequisites are installed
4. Try cleanup and redeploy: `make cleanup && make deploy-all`

---

**Enjoy your ArgoCD + Helm journey! 🚀**
