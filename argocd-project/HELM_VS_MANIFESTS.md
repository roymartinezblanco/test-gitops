# Helm-based ArgoCD Setup vs Plain Manifests

This project demonstrates how to use **Helm charts** with ArgoCD, as opposed to plain Kubernetes manifests.

## Key Differences from Plain Manifest Approach

### 1. **Application Structure**

#### Plain Manifests (test-gitops style):
```
app/
├── deployment.yaml
├── service.yaml
├── configmap.yaml
└── ingress.yaml
```

#### Helm Charts (this project):
```
helm-charts/guestbook/
├── Chart.yaml          # Helm chart metadata
├── values.yaml         # Configurable values
└── templates/          # Templated Kubernetes manifests
    ├── deployment.yaml
    ├── service.yaml
    ├── redis-deployment.yaml
    └── _helpers.tpl    # Template helpers
```

### 2. **Configuration Management**

#### Plain Manifests:
- Hardcoded values in YAML files
- Need separate files for different environments
- Changes require editing multiple files

#### Helm Charts:
- **Centralized configuration** in `values.yaml`
- **Template variables** using Go templating
- **Easy environment overrides** without changing templates
- **Reusable** across multiple deployments

Example from `values.yaml`:
```yaml
replicaCount: 1
image:
  repository: gcr.io/heptio-images/ks-guestbook-demo
  tag: "0.2"
service:
  type: ClusterIP
  port: 80
```

These values are referenced in templates:
```yaml
replicas: {{ .Values.replicaCount }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### 3. **ArgoCD Application Configuration**

#### Plain Manifests:
```yaml
spec:
  source:
    repoURL: https://github.com/user/repo.git
    path: app/
    targetRevision: HEAD
```

#### Helm Charts:
```yaml
spec:
  source:
    repoURL: https://github.com/user/repo.git
    path: helm-charts/guestbook
    targetRevision: HEAD
    helm:                           # Helm-specific configuration
      releaseName: guestbook
      valueFiles:
        - values.yaml
      values: |                     # Override values inline
        replicaCount: 3
```

### 4. **Benefits of Helm Approach**

#### ✅ **Parameterization**
- Single source of truth for configuration
- Override values per environment without changing templates
- Support for multiple environments (dev, staging, prod)

#### ✅ **Templating Power**
- Conditional resource creation: `{{- if .Values.redis.enabled }}`
- Dynamic naming: `{{ include "guestbook.fullname" . }}-redis`
- Helper functions for common patterns
- Loop over values to create multiple resources

#### ✅ **Dependency Management**
- Declare dependencies on other Helm charts
- Version pinning for dependencies
- Automatic dependency updates

#### ✅ **Packaging & Versioning**
- Package charts as `.tgz` files
- Semantic versioning via `Chart.yaml`
- Distribute via Helm repositories
- Rollback to previous chart versions

#### ✅ **Reduced Duplication**
- Shared templates via `_helpers.tpl`
- Common labels defined once
- DRY (Don't Repeat Yourself) principle

### 5. **Example: Multi-Environment Support**

#### With Plain Manifests:
You'd need separate directories or overlay tools:
```
manifests/
├── base/
│   ├── deployment.yaml
│   └── service.yaml
├── dev/
│   └── kustomization.yaml
└── prod/
    └── kustomization.yaml
```

#### With Helm:
Single chart + different value files:
```
helm-charts/guestbook/
├── Chart.yaml
├── values.yaml              # Default values
├── values-dev.yaml          # Dev overrides
├── values-staging.yaml      # Staging overrides
└── values-prod.yaml         # Production overrides
```

Deploy to different environments:
```yaml
# Dev environment
spec:
  source:
    helm:
      valueFiles:
        - values.yaml
        - values-dev.yaml

# Production environment
spec:
  source:
    helm:
      valueFiles:
        - values.yaml
        - values-prod.yaml
```

### 6. **Advanced Helm Features in ArgoCD**

#### **Value Overrides**
```yaml
spec:
  source:
    helm:
      values: |
        replicaCount: 5
        resources:
          limits:
            memory: 512Mi
```

#### **Release Name Control**
```yaml
spec:
  source:
    helm:
      releaseName: my-custom-name
```

#### **Helm Parameters**
```yaml
spec:
  source:
    helm:
      parameters:
        - name: replicaCount
          value: "3"
        - name: image.tag
          value: "1.0.0"
```

#### **Skip CRD Installation**
```yaml
spec:
  source:
    helm:
      skipCrds: true
```

### 7. **When to Use Helm vs Plain Manifests**

#### Use Helm when:
- ✅ You need to deploy the same app to multiple environments
- ✅ You have many configuration options to manage
- ✅ You want to package and version your application
- ✅ You need conditional resource creation
- ✅ You want to reuse community charts as dependencies

#### Use Plain Manifests when:
- ✅ Your application is very simple
- ✅ You have a single environment
- ✅ You prefer explicit, straightforward YAML
- ✅ You don't need templating or parameterization
- ✅ You want maximum transparency (what you see is what you get)

### 8. **ArgoCD Repo Server Role**

The ArgoCD **repo-server** is automatically included in the standard ArgoCD installation and plays a crucial role in Helm deployments:

#### What it does:
- **Clones Git repositories** containing your Helm charts
- **Renders Helm templates** using specified values
- **Generates final manifests** that ArgoCD will apply
- **Caches** rendered manifests for performance
- **Handles** Helm-specific operations (dependency updates, etc.)

#### How it works with Helm:
1. Repo-server clones your Git repository
2. Reads the Helm chart from the specified path
3. Merges values from multiple sources (values.yaml, values files, inline values)
4. Runs `helm template` to render the final Kubernetes manifests
5. Provides manifests to ArgoCD application controller
6. Application controller applies manifests to cluster

You can see the repo-server in action:
```bash
# View repo-server pods
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server

# View repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

### 9. **Migration Path**

If you have existing plain manifests and want to convert to Helm:

```bash
# 1. Create Helm chart structure
helm create my-app

# 2. Move your manifests to templates/
cp deployment.yaml my-app/templates/
cp service.yaml my-app/templates/

# 3. Parameterize values
# Replace hardcoded values with {{ .Values.* }} syntax

# 4. Test rendering
helm template my-app ./my-app

# 5. Update ArgoCD Application to use Helm
# Add helm: section to your Application spec
```

## Conclusion

This project uses Helm charts with ArgoCD to provide:
- **Flexibility** through parameterization
- **Reusability** across environments
- **Maintainability** through DRY principles
- **Professional packaging** with versioning
- **Power** of the repo-server for template rendering

The trade-off is slightly more complexity compared to plain manifests, but the benefits scale with your needs.
