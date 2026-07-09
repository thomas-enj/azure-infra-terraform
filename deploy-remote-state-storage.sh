export OWNER="thomas-enjalbert"
export RG_BACKEND="tenjalbertRG"
export SA_BACKEND="ststate${OWNER//-/}"

az group create --name "$RG_BACKEND" --location "francecentral"

az storage account create \
  --name           "$SA_BACKEND" \
  --resource-group "$RG_BACKEND" \
  --location       "francecentral" \
  --sku            Standard_LRS

az storage container create \
  --name         "tfstate" \
  --account-name "$SA_BACKEND"

az storage blob list \
  --container-name "tfstate" \
  --account-name   "$SA_BACKEND" \
  --output         table