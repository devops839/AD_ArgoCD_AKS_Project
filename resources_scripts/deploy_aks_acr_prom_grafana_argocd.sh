#!/bin/bash

# Set variables
RESOURCE_GROUP="demorg"
LOCATION="eastus"
ACR_NAME="demoacr839"
AKS_NAME="demoaks839"
NODE_POOL_NAME="demonp839"
NODE_VM_SIZE="Standard_DS2_v2"
MIN_NODES=1
MAX_NODES=2
MONITORING_NAMESPACE="monitoring"
ARGOCD_NAMESPACE="argocd"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="Grafana@123"
HELM_REPO_NAME="prometheus-community"
HELM_CHART="kube-prometheus-stack"
CHART_RELEASE_NAME="monitoring-stack"

echo "Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Standard --location $LOCATION

echo "Creating AKS Cluster with autoscaling enabled..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count $MIN_NODES \
    --enable-cluster-autoscaler \
    --min-count $MIN_NODES \
    --max-count $MAX_NODES \
    --nodepool-name $NODE_POOL_NAME \
    --node-vm-size $NODE_VM_SIZE \
    --enable-managed-identity \
    --vm-set-type VirtualMachineScaleSets \
    --location $LOCATION \
    --generate-ssh-keys

echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Check if Helm is installed, if not, install Helm
if ! command -v helm &> /dev/null; then
    echo "Helm not found, installing..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm is already installed."
fi

# Create Namespace for Monitoring
echo "Creating namespace '$MONITORING_NAMESPACE'..."
kubectl create namespace $MONITORING_NAMESPACE || echo "Namespace $MONITORING_NAMESPACE already exists"

# Add Prometheus Helm Repository
echo "Adding Helm repository..."
helm repo add $HELM_REPO_NAME https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus and Grafana
echo "Deploying Prometheus and Grafana using Helm..."
helm upgrade --install $CHART_RELEASE_NAME $HELM_REPO_NAME/$HELM_CHART \
    --namespace $MONITORING_NAMESPACE \
    --set grafana.adminUser=$GRAFANA_USER \
    --set grafana.adminPassword=$GRAFANA_PASSWORD

# Wait for Prometheus and Grafana to be Ready
echo "Waiting for Prometheus and Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/instance=$CHART_RELEASE_NAME -n $MONITORING_NAMESPACE

# Expose Grafana with LoadBalancer Service
echo "Exposing Grafana with LoadBalancer service..."
kubectl patch svc $CHART_RELEASE_NAME-grafana -n $MONITORING_NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'

# Get Grafana External IP
echo "Fetching Grafana service details..."
GRAFANA_IP=""
while [[ -z $GRAFANA_IP ]]; do
    echo "Waiting for external IP..."
    GRAFANA_IP=$(kubectl get svc $CHART_RELEASE_NAME-grafana -n $MONITORING_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    sleep 10
done

echo "Grafana is available at: http://$GRAFANA_IP"
echo "Login with Username: $GRAFANA_USER and Password: $GRAFANA_PASSWORD"

## --------------------------------------------
## Install ArgoCD for GitOps
## --------------------------------------------

# Create ArgoCD Namespace
echo "Creating ArgoCD namespace..."
kubectl create namespace $ARGOCD_NAMESPACE || echo "Namespace $ARGOCD_NAMESPACE already exists"

# Install ArgoCD using Helm
echo "Installing ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace $ARGOCD_NAMESPACE

# Wait for ArgoCD to be Ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=argocd-server -n $ARGOCD_NAMESPACE

# Expose ArgoCD using LoadBalancer
echo "Exposing ArgoCD Server with LoadBalancer service..."
kubectl patch svc argocd-server -n $ARGOCD_NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD External IP
echo "Fetching ArgoCD service details..."
ARGOCD_IP=""
while [[ -z $ARGOCD_IP ]]; do
    echo "Waiting for external IP..."
    ARGOCD_IP=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    sleep 10
done

# Get ArgoCD Initial Admin Password
echo "Fetching ArgoCD initial admin password..."
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}" | base64 --decode)

echo "ArgoCD is available at: http://$ARGOCD_IP"
echo "Login with Username: admin and Password: $ARGOCD_PASSWORD"

# Install ArgoCD CLI
if ! command -v argocd &> /dev/null; then
    echo "Installing ArgoCD CLI..."
    sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo chmod +x /usr/local/bin/argocd
else
    echo "ArgoCD CLI is already installed."
fi

echo "AKS Cluster, ACR, Monitoring, and ArgoCD setup completed successfully!"
