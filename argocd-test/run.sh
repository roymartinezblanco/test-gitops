kind create cluster --config kind-config.yaml
kubectl cluster-info --context kind-argocd-local
kubectl config use-context kind-argocd-local
kubectl cluster-info
kubectl wait --for=condition=Ready nodes --all --timeout=300s
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
kubectl apply -f argocd/applications/guestbook-git.yaml
kubectl wait --for=condition=Ready pods --all -n guestbook --timeout=300s
kind load docker-image argocd-labeler:latest -n argocd-local
