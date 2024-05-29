# Define variables
CLUSTER_NAME = prometheus-cluster
NAMESPACE = monitoring
IMAGE_NAME = myapp
DOCKERFILE = Dockerfile
MANIFESTS_DIR = k8s/

# Define commands
KIND = kind
KUBECTL = kubectl
HELM = helm
GO = go

.PHONY: all build test kind-cluster deploy-prometheus deploy-mimir apply-manifests clean

all: kind-cluster deploy-prometheus deploy-mimir apply-manifests

build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME) -f $(DOCKERFILE) .

test:
	@echo "Running Go tests..."
	$(GO) test ./...

kind-cluster:
	@echo "Creating kind cluster..."
	$(KIND) create cluster --name $(CLUSTER_NAME)

deploy-prometheus:
	@echo "Adding Helm repositories..."
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
	$(HELM) repo update

	@echo "Creating namespace '$(NAMESPACE)'..."
	$(KUBECTL) create namespace $(NAMESPACE)

	@echo "Deploying kube-prometheus-stack with remote write to Mimir..."
	$(HELM) install prometheus-stack prometheus-community/kube-prometheus-stack --namespace $(NAMESPACE) \
	--set prometheus.prometheusSpec.remoteWrite[0].url=http://mimir-nginx.monitoring.svc:80/api/v1/push

	@echo "Waiting for Prometheus and Grafana pods to be ready..."
	$(KUBECTL) wait --namespace $(NAMESPACE) \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/instance=prometheus-stack \
	  --timeout=5m

	@echo "Retrieving Grafana admin password..."
	GRAFANA_PASSWORD=$$($(KUBECTL) get secret --namespace $(NAMESPACE) prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode); \
	echo "Grafana admin password: $$GRAFANA_PASSWORD"

	@echo "Retrieving Grafana URL..."
	GRAFANA_URL=$$($(KUBECTL) get svc --namespace $(NAMESPACE) prometheus-stack-grafana -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"); \
	echo "Grafana URL: http://$$GRAFANA_URL"

deploy-mimir:
	@echo "Adding Grafana Helm repository..."
	$(HELM) repo add grafana https://grafana.github.io/helm-charts
	$(HELM) repo update

	@echo "Deploying Grafana Mimir..."
	$(HELM) install mimir grafana/mimir-distributed --namespace $(NAMESPACE) \
	--set distributor.replicaCount=1 \
	--set ingester.replicaCount=1 \
	--set querier.replicaCount=1 \
	--set store-gateway.replicaCount=1 \
	--set compactor.replicaCount=1 \
	--set alertmanager.replicaCount=1 \
	--set ruler.replicaCount=1 \
	--set metaMonitoring.enabled=true \
	--set metaMonitoring.serviceMonitor.enabled=true

	@echo "Waiting for Mimir pods to be ready..."
	$(KUBECTL) wait --namespace $(NAMESPACE) \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/name=mimir \
	  --timeout=5m

apply-manifests:
	@echo "Applying Kubernetes manifests from $(MANIFESTS_DIR)..."
	$(KUBECTL) apply -f $(MANIFESTS_DIR)

clean:
	@echo "Deleting kind cluster..."
	$(KIND) delete cluster --name $(CLUSTER_NAME)
