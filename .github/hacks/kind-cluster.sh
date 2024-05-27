#!/bin/bash

# Create a kind cluster
echo "Creating kind cluster..."
kind create cluster --name prometheus-cluster

# Add the stable Helm repository
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update

# Create a namespace for monitoring
echo "Creating namespace 'monitoring'..."
kubectl create namespace monitoring

# Deploy the kube-prometheus-stack
echo "Deploying kube-prometheus-stack..."
helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring

# Wait for all pods to be up and running
echo "Waiting for Prometheus and Grafana pods to be ready..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=prometheus-stack \
  --timeout=5m

# Get Grafana admin password
echo "Retrieving Grafana admin password..."
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana admin password: $GRAFANA_PASSWORD"

echo "kube-prometheus-stack deployment completed."
