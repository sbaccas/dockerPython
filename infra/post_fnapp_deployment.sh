# Variables
storage_rg="table_storage_rg"
storage_account="mstablestorage28882"
table_name="people"
function_rg="jn20"
function_app_name="skyfnappepxbp22ymeghk"  # <-- Replace this with the actual name

# 1. Create the storage account in a new RG
az group create --name $storage_rg --location canadacentral

az storage account create \
  --name $storage_account \
  --resource-group $storage_rg \
  --location canadacentral \
  --sku Standard_LRS

# 2. Fetch the connection string
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --name $storage_account \
  --resource-group $storage_rg \
  --query connectionString \
  --output tsv)

# 3. Create table
az storage table create \
  --name $table_name \
  --account-name $storage_account \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

# 4. Insert entities
az storage entity insert \
  --table-name $table_name \
  --entity PartitionKey=TestPartition RowKey=1 Name=Alice Age=30 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

az storage entity insert \
  --table-name $table_name \
  --entity PartitionKey=TestPartition RowKey=2 Name=Bob Age=42 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

az storage entity insert \
  --table-name $table_name \
  --entity PartitionKey=TestPartition RowKey=3 Name=Charlie Age=27 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

# 5. Set environment variables on the Function App
az functionapp config appsettings set \
  --name $function_app_name \
  --resource-group $function_rg \
  --settings \
  MG_ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\
  STORAGE_ACCOUNT_NAME=$storage_account \
  TABLE_NAME=$table_name

# 6. Get the Function App's Managed Identity principal ID
principal_id=$(az functionapp identity show \
  --name $function_app_name \
  --resource-group $function_rg \
  --query principalId \
  --output tsv)
# reader at mg 
az role assignment create \
  --assignee $principal_id \
  --role "Reader" \
  --scope "/providers/Microsoft.Management/managementGroups/subRoot"


# 7. Assign Storage Table Data Reader role
az role assignment create \
  --assignee $principal_id \
  --role "Storage Table Data Reader" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$storage_rg/providers/Microsoft.Storage/storageAccounts/$storage_account"

curl -X POST https://dkfuncwithidentity.azurewebsites.net/api/dockerPython \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice"}'
