#!/bin/bash

# Variables
RESOURCE_GROUP="demorg"
LOCATION="eastus"
VM_NAME="devops-agent-vm"
IMAGE="UbuntuLTS"
VM_SIZE="Standard_DS2_v2"
ADMIN_USER="agent"
ADMIN_PASSWORD="agent#123"

# Create the VM with a password
echo "Creating VM..."
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image $IMAGE \
    --admin-username $ADMIN_USER \
    --admin-password $ADMIN_PASSWORD \
    --size $VM_SIZE \
    --custom-data cloud-init.yaml

echo "VM $VM_NAME created successfully!"
