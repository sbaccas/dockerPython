az group create \
  --name jn20 \
  --location canadacentral

az deployment group create \
  --name funcDockerDeploy \
  --resource-group jn20 \
  --template-file azfunction.json \
  --parameters \
    appName="dockerPythonJn18try1" \
    acrPassword="cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy" \
    acrServer=shanesdocker.azurecr.io \
    acrUsername=shanesdocker \
    imageName=shanesdocker.azurecr.io/jn20image:latest


