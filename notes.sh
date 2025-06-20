az storage account create --name demoshanecontainer --location eastus --resource-group AzureFunctionsContainers-rg --sku Standard_LRS --allow-blob-public-access false --allow-shared-key-access false

principalId=$(az identity create --name <USER_IDENTITY_NAME> --resource-group AzureFunctionsContainers-rg --location eastus --query principalId -o tsv) 
acrId=$(az acr show --name <REGISTRY_NAME> --query id --output tsv)
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role acrpull --scope $acrId
storageId=$(az storage account show --resource-group AzureFunctionsContainers-rg --name <STORAGE_NAME> --query 'id' -o tsv)
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role "Storage Blob Data Owner" --scope $storageId



# Create User-Assigned Managed Identity
principalId=$(az identity create \
  --name func-container-identity \
  --resource-group AzureFunctionsContainers-rg \
  --location eastus \
  --query principalId -o tsv)

# Get ACR resource ID
acrId=$(az acr show \
  --name shanesdocker \
  --query id --output tsv)

# Assign 'AcrPull' role so Function can pull from container registry
az role assignment create \
  --assignee-object-id $principalId \
  --assignee-principal-type ServicePrincipal \
  --role acrpull \
  --scope $acrId

# Get Storage Account ID
storageId=$(az storage account show \
  --resource-group AzureFunctionsContainers-rg \
  --name demoshanecontainer \
  --query 'id' -o tsv)

# Assign 'Storage Blob Data Owner' so Function can write logs or state if needed
az role assignment create \
  --assignee-object-id $principalId \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Owner" \
  --scope $storageId





uami_name="func-container-identity"
group="AzureFunctionsContainers-rg"
storage_name="demoshanecontainer"
app_name="shane-func-container"

# Get the UAMI resource ID
UAMI_RESOURCE_ID=$(az identity show \
  --name $uami_name \
  --resource-group $group \
  --query id -o tsv)

# Create the function app
az functionapp create \
  --name $app_name \
  --storage-account $storage_name \
  --environment MyContainerappEnvironment \
  --workload-profile-name "Consumption" \
  --resource-group $group \
  --functions-version 4 \
  --assign-identity $UAMI_RESOURCE_ID

az deployment group create \
  --name funcDockerDeploy \
  --resource-group azFunc-rgJn18 \
  --template-file azfunction.json \
  --parameters \
    acrPassword="cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy" \
    acrServer=shanesdocker.azurecr.io \
    acrUsername=shanesdocker \
    akvName=dummy-akv \
    branch=latest \
    organizationName=dummy-org \
    projectName=dummy-project \
    serviceConnectionName=dummy-conn \
    agentPool=dummy-pool



  #Pull container img from ACR 

  # Get UAMI resource ID
UAMI_RESOURCE_ID=$(az identity show \
  --name func-container-identity \
  --resource-group AzureFunctionsContainers-rg \
  --query id -o tsv)

# Patch the function app to use your container image from ACR via UAMI
UAMI_RESOURCE_ID=$(az identity show --name <USER_IDENTITY_NAME> --resource-group AzureFunctionsContainers-rg --query id -o tsv)
az resource patch --resource-group AzureFunctionsContainers-rg --name <APP_NAME> --resource-type "Microsoft.Web/sites" --properties "{ \"siteConfig\": { \"linuxFxVersion\": \"DOCKER|<REGISTRY_NAME>.azurecr.io/azurefunctionsimage:v1.0.0\", \"acrUseManagedIdentityCreds\": true, \"acrUserManagedIdentityID\":\"$UAMI_RESOURCE_ID\", \"appSettings\": [{\"name\": \"DOCKER_REGISTRY_SERVER_URL\", \"value\": \"<REGISTRY_NAME>.azurecr.io\"}]}}"


# Stroage creation. 
 az storage account show-connection-string   --name <your-storage-account-name>   --resource-group azFunc-rgJn18   --query connectionString   --output tsv

export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --name myfuncstorage28882 \
  --resource-group jn19 \
  --query connectionString \
  --output tsv)

az storage table create \
  --name people \
  --account-name myfuncstorage28882 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

az storage entity insert \
  --table-name people \
  --entity PartitionKey=TestPartition RowKey=1 Name=Alice Age=30 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

az storage entity insert \
  --table-name people \
  --entity PartitionKey=TestPartition RowKey=2 Name=Bob Age=42 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

az storage entity insert \
  --table-name people \
  --entity PartitionKey=TestPartition RowKey=3 Name=Charlie Age=27 \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"

#verify! 
az storage entity query \
  --table-name People \
  --connection-string "$AZURE_STORAGE_CONNECTION_STRING"


# deploying azure fn 
az deployment group create \
  --resource-group azFunc-rgJn18 \
  --template-file azfunction.json \
  --parameters \
    appName="dockerPythonJn18try1" \
    acrUsername="shanesdocker" \
    acrPassword="cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy" \
    acrServer="shanesdocker.azurecr.io" \
    imageName="shanesdocker.azurecr.io/dockerPython:latest"


#Updating function 

FUNCTION_APP_NAME=skyfnappmq6lttb3dhakslatest  # ← your function app name
RESOURCE_GROUP=azFunc-rgJn18                  # ← your resource group
ACR_SERVER=shanesdocker.azurecr.io
IMAGE_NAME=dockerpython:latest
ACR_USERNAME=shanesdocker
ACR_PASSWORD='cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy'


az functionapp config container set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_SERVER/$IMAGE_NAME \
  --docker-registry-server-url https://$ACR_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

az functionapp restart --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP

az deployment group create \
  --resource-group rgJun19 \
  --template-file azfunction.json \
  --parameters \
    appName="dkPythnJn19try2" \
    acrUsername="shanesdocker" \
    acrPassword="cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy" \
    acrServer="shanesdocker.azurecr.io" \
    imageName="shanesdocker.azurecr.io/dockerPython:latest"

az deployment group create \
  --resource-group rgJn1 \
  --template-file azfunction.json \
  --parameters \
    appName="dkPythnJn1try1" \
    acrUsername="shanesdocker" \
    acrPassword="cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy" \
    acrServer="shanesdocker.azurecr.io" \
    imageName="shanesdocker.azurecr.io/dockerpython:latest"

