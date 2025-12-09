#!/bin/bash
set -e

echo "🚀 Setting up Gitea for local Git repository..."

# Create gitea namespace
echo "📦 Creating Gitea namespace..."
kubectl create namespace gitea --dry-run=client -o yaml | kubectl apply -f -

# Deploy Gitea using manifests
echo "⬇️  Deploying Gitea..."

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-data
  namespace: gitea
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      containers:
      - name: gitea
        image: gitea/gitea:1.21
        ports:
        - containerPort: 3000
          name: http
        - containerPort: 22
          name: ssh
        env:
        - name: GITEA__database__DB_TYPE
          value: "sqlite3"
        - name: GITEA__server__ROOT_URL
          value: "http://gitea.gitea.svc.cluster.local:3000"
        - name: GITEA__server__HTTP_PORT
          value: "3000"
        - name: GITEA__security__INSTALL_LOCK
          value: "true"
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: gitea-data
---
apiVersion: v1
kind: Service
metadata:
  name: gitea
  namespace: gitea
spec:
  type: ClusterIP
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
    name: http
  - port: 22
    targetPort: 22
    protocol: TCP
    name: ssh
  selector:
    app: gitea
EOF

echo "⏳ Waiting for Gitea to be ready..."
kubectl wait --for=condition=Ready pod -l app=gitea -n gitea --timeout=300s

echo "✅ Gitea deployed successfully!"
echo ""
echo "🌐 To access Gitea:"
echo "   kubectl port-forward svc/gitea -n gitea 3000:3000"
echo "   Then open: http://localhost:3000"
echo ""
echo "Next steps:"
echo "  1. Access Gitea and create a user (admin/admin)"
echo "  2. Create a repository called 'argocd-config'"
echo "  3. Push your helm-charts to the repository"
echo "  4. Configure ArgoCD to use http://gitea.gitea.svc.cluster.local:3000/<user>/argocd-config"
