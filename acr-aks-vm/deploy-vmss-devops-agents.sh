#!/bin/bash

# Set Variables
RESOURCE_GROUP="demorg"
LOCATION="eastus"
VMSS_NAME="devops-agent-vmss"
ADMIN_USER="azureuser"
ADMIN_PASSWORD="vmadmin@1234"
VM_SIZE="Standard_DS2_v2"
INSTANCE_COUNT=1
MIN_INSTANCES=1
MAX_INSTANCES=3
DEVOPS_ORG="https://dev.azure.com/YOUR_ORG"
AGENT_POOL="myagents"
PAT_TOKEN="6hh2umc4gk9noucfHv6gX92ahh8E7sieTNxaE5Ml1MAT33hIRUxOJQQJ99BAACAAAAAAAAAAAAASAZDOeIGf"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create VMSS for Azure DevOps agents
az vmss create \
    --resource-group $RESOURCE_GROUP \
    --name $VMSS_NAME \
    --image UbuntuLTS \
    --admin-username $ADMIN_USER \
    --admin-password $ADMIN_PASSWORD \
    --instance-count $INSTANCE_COUNT \
    --vm-sku $VM_SIZE \
    --upgrade-policy-mode automatic \
    --custom-data cloud-init.yaml  # Reference to cloud-init script

# Enable auto-scaling for VMSS
az monitor autoscale create \
    --resource-group $RESOURCE_GROUP \
    --name "devops-agent-autoscale" \
    --target-resource $VMSS_NAME \
    --min-count $MIN_INSTANCES \
    --max-count $MAX_INSTANCES \
    --count $INSTANCE_COUNT

# Scaling Rules
az monitor autoscale rule create \
    --resource-group $RESOURCE_GROUP \
    --autoscale-name "devops-agent-autoscale" \
    --condition "Percentage CPU > 70 avg 5m" \
    --scale out 1

az monitor autoscale rule create \
    --resource-group $RESOURCE_GROUP \
    --autoscale-name "devops-agent-autoscale" \
    --condition "Percentage CPU < 30 avg 5m" \
    --scale in 1

echo "VMSS for Azure DevOps agents created with auto-scaling enabled."
