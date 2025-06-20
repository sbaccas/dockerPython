docker build -t jn20image .
docker tag jn20image shanesdocker.azurecr.io/jn20image
az acr login

docker push shanesdocker.azurecr.io/jn20image

# then we confirm
az acr repository list \
  --name shanesdocker \
  --output table


##################################################
############## ReBake and PUSH ###################
##################################################

docker build -t jn20image:v2 .

docker tag jn20image:v2 shanesdocker.azurecr.io/jn20image:v2

docker push shanesdocker.azurecr.io/jn20image:v2

az functionapp config container set \
  --name skyfnappepxbp22ymeghk \
  --resource-group jn20 \
  --image shanesdocker.azurecr.io/jn20image:v2 \
  --registry-username shanesdocker \
  --registry-password "cA/Q8ZdxxRpZnSQPeTU/CmqsqFb1SmlBw0SxDkrvrf+ACRDTDNRy"

az functionapp restart \
  --name skyfnappepxbp22ymeghk \
  --resource-group jn20
