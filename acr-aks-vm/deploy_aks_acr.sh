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

echo "Installation completed successfully!"
