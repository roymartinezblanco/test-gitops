.PHONY: help create-cluster install-argocd deploy-guestbook deploy-all cleanup setup-gitea status port-forward-argocd port-forward-guestbook argocd-password

help: ## Show this help message
	@echo "ArgoCD Local Development Environment"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""

create-cluster: ## Create Kind cluster
	@./scripts/create-cluster.sh

install-argocd: ## Install ArgoCD
	@./scripts/install-argocd.sh

deploy-guestbook: ## Deploy guestbook application
	@./scripts/deploy-guestbook.sh

deploy-all: ## Complete setup (cluster + ArgoCD + guestbook)
	@./scripts/deploy-all.sh

setup-gitea: ## Setup Gitea for local Git repository
	@./scripts/setup-gitea.sh

cleanup: ## Delete the Kind cluster
	@./scripts/cleanup.sh

status: ## Show status of all resources
	@echo "=== ArgoCD Status ==="
	@kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD not installed"
	@echo ""
	@echo "=== Guestbook Status ==="
	@kubectl get pods,svc -n guestbook 2>/dev/null || echo "Guestbook not deployed"
	@echo ""
	@echo "=== ArgoCD Applications ==="
	@kubectl get applications -n argocd 2>/dev/null || echo "No applications found"

argocd-password: ## Get ArgoCD admin password
	@echo "ArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo || echo "ArgoCD not installed"

port-forward-argocd: ## Port forward ArgoCD UI (https://localhost:8080)
	@echo "🌐 ArgoCD UI will be available at: https://localhost:8080"
	@echo "   Username: admin"
	@echo "   Password: (run 'make argocd-password')"
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

port-forward-guestbook: ## Port forward Guestbook UI (http://localhost:8081)
	@echo "🌐 Guestbook UI will be available at: http://localhost:8081"
	@kubectl port-forward svc/guestbook-guestbook-ui -n guestbook 8081:80

logs-guestbook: ## Show guestbook logs
	@kubectl logs -n guestbook -l app=guestbook --tail=50 -f

logs-argocd: ## Show ArgoCD server logs
	@kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50 -f

helm-template: ## Show rendered Helm template
	@helm template guestbook ./helm-charts/guestbook

helm-install: ## Install guestbook using Helm directly
	@helm upgrade --install guestbook ./helm-charts/guestbook \
		--namespace guestbook \
		--create-namespace \
		--wait

helm-uninstall: ## Uninstall guestbook Helm release
	@helm uninstall guestbook -n guestbook

argocd-sync: ## Manually sync ArgoCD application
	@kubectl -n argocd patch application guestbook -p '{"operation":{"initiatedBy":{"username":"manual"},"sync":{"revision":"HEAD"}}}' --type merge

argocd-refresh: ## Refresh ArgoCD application
	@kubectl -n argocd patch application guestbook -p '{"operation":{"initiatedBy":{"username":"manual"},"info":[{"name":"Reason","value":"Manual refresh"}]}}' --type merge

describe-app: ## Describe ArgoCD guestbook application
	@kubectl describe application guestbook -n argocd

get-app: ## Get ArgoCD guestbook application
	@kubectl get application guestbook -n argocd -o yaml
