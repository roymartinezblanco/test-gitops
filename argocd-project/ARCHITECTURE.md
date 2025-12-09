# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Your Computer                            │
│                                                                   │
│  ┌────────────────┐                    ┌────────────────┐       │
│  │   Browser      │                    │   Terminal     │       │
│  │                │                    │                │       │
│  │ localhost:8080 │◄───────────────┐  │  kubectl CLI   │       │
│  │ localhost:8081 │                │  │  helm CLI      │       │
│  └────────────────┘                │  │  make commands │       │
│         │                          │  └────────┬───────┘       │
│         │ Port Forward             │           │               │
│         │                          │           │ API Calls     │
└─────────┼──────────────────────────┼───────────┼───────────────┘
          │                          │           │
          │                          │           ▼
┌─────────┼──────────────────────────┼───────────────────────────┐
│         │    Kind Cluster (Docker) │                            │
│         │                          │                            │
│  ┌──────┴───────────────────┐     │                            │
│  │  Control Plane Node      │     │                            │
│  │  ┌────────────────────┐  │     │                            │
│  │  │  Kubernetes API    │◄─┼─────┘                            │
│  │  │  Server            │  │                                   │
│  │  └────────────────────┘  │                                   │
│  └──────────────────────────┘                                   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Namespace: argocd                               │  │
│  │  ┌─────────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │ argocd-server   │  │ repo-server  │  │ application │ │  │
│  │  │   (API/UI)      │  │              │  │  controller │ │  │
│  │  │                 │  │ - Clone Git  │  │             │ │  │
│  │  │ Port: 443       │◄─┤ - Render     │◄─┤ - Watch    │ │  │
│  │  │                 │  │   Helm       │  │ - Sync      │ │  │
│  │  └────────┬────────┘  │ - Generate   │  │ - Health    │ │  │
│  │           │            │   Manifests  │  │   Check     │ │  │
│  │           │            └──────────────┘  └─────────────┘ │  │
│  └───────────┼───────────────────────────────────────────────┘  │
│              │ Applies Resources                                │
│              ▼                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Namespace: guestbook                            │  │
│  │                                                            │  │
│  │  ┌──────────────────┐              ┌─────────────────┐   │  │
│  │  │  Guestbook UI    │              │  Redis          │   │  │
│  │  │  Deployment      │──────────────│  Deployment     │   │  │
│  │  │                  │   Reads/     │                 │   │  │
│  │  │  Replicas: 1     │   Writes     │  Replicas: 1    │   │  │
│  │  │  Port: 2379      │              │  Port: 6379     │   │  │
│  │  └──────┬───────────┘              └────────┬────────┘   │  │
│  │         │                                   │             │  │
│  │         │                                   │             │  │
│  │  ┌──────┴───────────┐              ┌───────┴─────────┐   │  │
│  │  │  Service         │              │  Service        │   │  │
│  │  │  guestbook-ui    │              │  guestbook-redis│   │  │
│  │  │  Port: 80        │              │  Port: 6379     │   │  │
│  │  └──────────────────┘              └─────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Worker Node 1                      Worker Node 2                │
│  (Hosts various pods)               (Hosts various pods)         │
└───────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Helm Deployment Flow (Current Setup)

```
Developer                Helm CLI              Kubernetes API         Pods
    │                       │                       │                   │
    │ 1. Edit values.yaml   │                       │                   │
    │─────────────────────► │                       │                   │
    │                       │                       │                   │
    │ 2. helm upgrade       │                       │                   │
    │─────────────────────► │                       │                   │
    │                       │ 3. Render templates  │                   │
    │                       │   (using values)     │                   │
    │                       │                       │                   │
    │                       │ 4. Apply manifests   │                   │
    │                       │─────────────────────►│                   │
    │                       │                       │ 5. Create/Update │
    │                       │                       │─────────────────►│
    │                       │                       │                   │
    │                       │ 6. Wait for ready    │                   │
    │                       │◄─────────────────────│                   │
    │ 7. Success            │                       │                   │
    │◄─────────────────────│                       │                   │
```

### GitOps Flow (With Git Repository)

```
Developer    Git Repo     ArgoCD          Repo Server      K8s API      Pods
    │            │          │                  │              │          │
    │ 1. Push    │          │                  │              │          │
    │  changes   │          │                  │              │          │
    │───────────►│          │                  │              │          │
    │            │          │                  │              │          │
    │            │  2. Detect change           │              │          │
    │            │◄─────────│                  │              │          │
    │            │          │                  │              │          │
    │            │          │  3. Clone repo   │              │          │
    │            │          │─────────────────►│              │          │
    │            │          │                  │              │          │
    │            │          │  4. Render Helm  │              │          │
    │            │          │     templates    │              │          │
    │            │          │                  │              │          │
    │            │          │  5. Return       │              │          │
    │            │          │     manifests    │              │          │
    │            │          │◄─────────────────│              │          │
    │            │          │                  │              │          │
    │            │          │  6. Compare with cluster        │          │
    │            │          │─────────────────────────────────►          │
    │            │          │                  │              │          │
    │            │          │  7. Apply diff   │              │          │
    │            │          │─────────────────────────────────►          │
    │            │          │                  │              │          │
    │            │          │                  │              │  8. Update│
    │            │          │                  │              │─────────►│
    │            │          │                  │              │          │
    │            │          │  9. Health check │              │          │
    │            │          │◄─────────────────────────────────────────│
    │            │          │                  │              │          │
    │  10. Check UI         │                  │              │          │
    │◄──────────────────────│                  │              │          │
```

## Component Responsibilities

### ArgoCD Components

```
┌─────────────────────────────────────────────────────────────┐
│ argocd-server                                                │
│ • REST API for UI and CLI                                    │
│ • Authentication & Authorization                             │
│ • User interface                                             │
│ • Webhook receiver for Git notifications                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ argocd-repo-server                                           │
│ • Clones Git repositories                                    │
│ • Generates Kubernetes manifests from:                       │
│   - Helm charts (helm template)                              │
│   - Kustomize                                                │
│   - Plain YAML                                               │
│ • Caches generated manifests                                 │
│ • This is KEY for Helm integration! ⭐                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ argocd-application-controller                                │
│ • Watches Applications                                       │
│ • Compares desired state (Git) vs actual state (cluster)     │
│ • Syncs resources                                            │
│ • Health assessment                                          │
│ • Automated sync and self-healing                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ argocd-dex-server (optional)                                 │
│ • SSO integration                                            │
│ • OIDC, SAML, LDAP, etc.                                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ argocd-redis                                                 │
│ • Cache for repo data                                        │
│ • Session storage                                            │
└─────────────────────────────────────────────────────────────┘
```

## Helm Chart Structure

```
helm-charts/guestbook/
│
├── Chart.yaml                 # Metadata
│   ├── name: guestbook
│   ├── version: 1.0.0
│   └── description: ...
│
├── values.yaml                # Default configuration
│   ├── replicaCount: 1
│   ├── image:
│   │   ├── repository: ...
│   │   └── tag: ...
│   └── service:
│       ├── type: ClusterIP
│       └── port: 80
│
└── templates/                 # Kubernetes manifests
    │
    ├── _helpers.tpl          # Template functions
    │   ├── guestbook.fullname
    │   ├── guestbook.labels
    │   └── guestbook.selectorLabels
    │
    ├── deployment.yaml       # Uses: {{ .Values.* }}
    │   └── Renders to actual Deployment
    │
    ├── service.yaml          # Uses: {{ include "guestbook.fullname" . }}
    │   └── Renders to actual Service
    │
    ├── redis-deployment.yaml # Conditional: {{- if .Values.redis.enabled }}
    │   └── Renders only if enabled
    │
    └── redis-service.yaml    # Conditional: {{- if .Values.redis.enabled }}
        └── Renders only if enabled

When you run: helm template guestbook ./helm-charts/guestbook
              ↓
All templates are processed with values.yaml
              ↓
Output: Plain Kubernetes YAML manifests
              ↓
These manifests are what actually get applied to the cluster
```

## How Helm Values Work

```
Developer edits values.yaml:
┌─────────────────────────┐
│ values.yaml             │
│ ─────────────────────── │
│ replicaCount: 3         │◄─── Changed from 1 to 3
│ image:                  │
│   repository: myapp     │
│   tag: "1.0.0"          │
│ service:                │
│   type: LoadBalancer    │◄─── Changed from ClusterIP
│   port: 80              │
└─────────────────────────┘
            │
            │ helm upgrade
            ▼
┌─────────────────────────┐
│ Template Processing     │
│ ─────────────────────── │
│ templates/deployment:   │
│   replicas: {{ .Values. │
│     replicaCount }}     │
│                         │
│ Becomes:                │
│   replicas: 3           │◄─── Template replaced with value
└─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│ Final Manifest          │
│ ─────────────────────── │
│ apiVersion: apps/v1     │
│ kind: Deployment        │
│ spec:                   │
│   replicas: 3           │◄─── Actual value in cluster
│   ...                   │
└─────────────────────────┘
            │
            │ kubectl apply
            ▼
┌─────────────────────────┐
│ Kubernetes Cluster      │
│ ─────────────────────── │
│ 3 pods running          │◄─── Scaled to 3 replicas
└─────────────────────────┘
```

## Port Forwarding Explained

```
Your Computer                  Kind Cluster
┌──────────────┐              ┌─────────────────────────────┐
│              │              │                             │
│  Browser     │              │  Service: argocd-server     │
│  localhost:  │              │  ClusterIP: 10.96.x.x       │
│  8080        │              │  Port: 443                  │
│      │       │              │       ▲                     │
│      │       │              │       │                     │
│      │       │              │  ┌────┴─────┐              │
│      │       │              │  │  Pod     │              │
│      │       │              │  │ ArgoCD   │              │
│      │       │              │  │ Server   │              │
│      │       │              │  └──────────┘              │
└──────┼───────┘              └─────────────────────────────┘
       │                                   ▲
       │ kubectl port-forward              │
       └───────────────────────────────────┘
       
       This creates a tunnel:
       localhost:8080 ───► argocd-server:443
       
       Without port-forward, you can't access services
       from outside the cluster (they're ClusterIP)
```

## Why This Architecture?

### Benefits

1. **Separation of Concerns**
   - ArgoCD manages sync
   - Helm manages templating
   - Kubernetes manages runtime

2. **Declarative Configuration**
   - Git is source of truth
   - Cluster automatically converges to desired state

3. **Auditability**
   - All changes in Git history
   - Who changed what, when

4. **Rollback Capability**
   - Git revert = cluster rollback
   - ArgoCD tracks history

5. **Multi-Environment**
   - Same chart, different values
   - Consistent deployment across envs

## Comparison: Direct Helm vs ArgoCD

### Direct Helm
```
You ─► helm upgrade ─► Kubernetes ─► Pods
     (manual)
```
- ✅ Simple
- ✅ Direct control
- ❌ Manual process
- ❌ No audit trail
- ❌ Config drift possible

### ArgoCD with Helm
```
You ─► Git push ─► ArgoCD ─► Kubernetes ─► Pods
                   (automatic)
```
- ✅ Automated
- ✅ Git audit trail
- ✅ Self-healing
- ✅ Prevents drift
- ✅ Rollback easy
- ❌ More complex setup

## This Project's Approach

**Current Setup**: Direct Helm (simpler for learning)
**Recommended Next Step**: Git-based ArgoCD (production-ready)

You have both options ready to use!
