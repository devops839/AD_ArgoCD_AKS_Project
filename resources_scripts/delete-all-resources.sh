#!/bin/bash
# Set Variables
RESOURCE_GROUP="demorg"

# Delete all resources within the resource group
echo "Deleting all resources in Resource Group: $RESOURCE_GROUP"
az group delete --name $RESOURCE_GROUP --yes --no-wait --verbose

echo "Deletion initiated. All resources in Resource Group $RESOURCE_GROUP will be deleted."

