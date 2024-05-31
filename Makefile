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

.PHONY: all build test kind-cluster deploy-prometheus apply-manifests clean

all: kind-cluster deploy-prometheus apply-manifests

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
	--set prometheus.prometheusSpec.additionalScrapeConfigs[0].job_name=kube-secrets-exporter \
	--set prometheus.prometheusSpec.additionalScrapeConfigs[0].static_configs[0].targets[0]=kube-secrets-exporter.monitoring.svc.cluster.local:8080 \
	--set prometheus.prometheusSpec.additionalScrapeConfigs[0].metrics_path=/metrics
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

apply-manifests:
	@echo "Applying Kubernetes manifests from $(MANIFESTS_DIR)..."
	$(KUBECTL) apply -f $(MANIFESTS_DIR)

clean:
	@echo "Deleting kind cluster..."
	$(KIND) delete cluster --name $(CLUSTER_NAME)
