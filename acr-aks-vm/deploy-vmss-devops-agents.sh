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
DEVOPS_ORG="https://dev.azure.com/pavank839"
AGENT_POOL="myagents"
PAT_TOKEN="6hh2umc4gk9noucfHv6gX92ahh8E7sieTNxaE5Ml1MAT33hIRUxOJQQJ99BAACAAAAAAAAAAAAASAZDOeIGf"
VNET_NAME="demo-vnet"
SUBNET_NAME="demo-subnet"
NSG_NAME="demo-nsg"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Virtual Network and Subnet
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.0.0.0/24

# Create Network Security Group (NSG)
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name $NSG_NAME

# Add NSG Rule to Allow SonarQube (Port 9000)
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name AllowSonarQube \
    --protocol tcp \
    --direction inbound \
    --priority 1000 \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 9000 \
    --access allow

# Create VMSS for Azure DevOps agents with the NSG
az vmss create \
    --resource-group $RESOURCE_GROUP \
    --name $VMSS_NAME \
    --image Ubuntu2204 \
    --admin-username $ADMIN_USER \
    --admin-password $ADMIN_PASSWORD \
    --instance-count $INSTANCE_COUNT \
    --vm-sku $VM_SIZE \
    --upgrade-policy-mode automatic \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_NAME \
    --nsg $NSG_NAME \
    --custom-data cloud-init.yaml  # Reference to cloud-init script

# Get the VMSS Resource ID for autoscaling
VMSS_RESOURCE_ID=$(az vmss show \
    --resource-group $RESOURCE_GROUP \
    --name $VMSS_NAME \
    --query "id" \
    --output tsv)

# Enable auto-scaling for VMSS
az monitor autoscale create \
    --resource-group $RESOURCE_GROUP \
    --name "devops-agent-autoscale" \
    --target-resource $VMSS_RESOURCE_ID \
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

echo "VMSS for Azure DevOps agents created with auto-scaling enabled and NSG rule to open port 9000 for SonarQube."
