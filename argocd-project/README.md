# ArgoCD Local Development Environment

This project sets up a local Kubernetes cluster using Kind with ArgoCD and a sample guestbook application using Helm.

## Prerequisites

- Docker
- kubectl
- kind
- helm

## Installation

### 1. Install Prerequisites (if needed)

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Quick Start

### 1. Create the Kind Cluster

```bash
./scripts/create-cluster.sh
```

### 2. Install ArgoCD

```bash
./scripts/install-argocd.sh
```

### 3. Access ArgoCD UI

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward to access the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD at: https://localhost:8080
- Username: `admin`
- Password: (from the command above)

### 4. Deploy the Guestbook Application

```bash
./scripts/deploy-guestbook.sh
```

### 5. Access the Guestbook Application

```bash
# Port forward to access the guestbook
kubectl port-forward svc/guestbook-ui -n guestbook 8081:80
```

Access Guestbook at: http://localhost:8081

## Project Structure

```
.
├── README.md
├── kind-config.yaml          # Kind cluster configuration
├── scripts/
│   ├── create-cluster.sh     # Creates the kind cluster
│   ├── install-argocd.sh     # Installs ArgoCD
│   ├── deploy-guestbook.sh   # Deploys the guestbook app
│   └── cleanup.sh            # Cleanup script
├── argocd/
│   └── applications/
│       └── guestbook.yaml    # ArgoCD Application manifest
└── helm-charts/
    └── guestbook/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            └── ...
```

## Managing the Environment

### View ArgoCD Applications

```bash
kubectl get applications -n argocd
```

### Sync Application Manually

```bash
kubectl -n argocd patch application guestbook -p '{"spec":{"syncPolicy":{"automated":null}}}' --type merge
argocd app sync guestbook
```

### Delete the Cluster

```bash
./scripts/cleanup.sh
```

## Troubleshooting

### Check ArgoCD Status

```bash
kubectl get pods -n argocd
```

### Check Guestbook Status

```bash
kubectl get pods -n guestbook
kubectl get svc -n guestbook
```

### View ArgoCD Logs

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## Features

- ✅ Kind cluster with local registry
- ✅ ArgoCD with repo server
- ✅ Sample guestbook application deployed via Helm
- ✅ Automated sync policy
- ✅ Self-healing enabled
- ✅ Pruning enabled

## Notes

- The ArgoCD repo server is automatically configured as part of the standard ArgoCD installation
- The guestbook application is deployed using Helm charts stored locally
- Auto-sync is enabled by default for the guestbook application
