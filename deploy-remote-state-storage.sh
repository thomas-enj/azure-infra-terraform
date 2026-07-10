export OWNER="thomas-enjalbert"
export RG_BACKEND="tenjalbertRG"
export SA_BACKEND="ststate${OWNER//-/}"

az group create --name "$RG_BACKEND" --location "francecentral"

az storage account create \
  --name           "$SA_BACKEND" \
  --resource-group "$RG_BACKEND" \
  --location       "francecentral" \
  --sku            Standard_LRS

sleep 15

az storage container create \
  --name         "tfstate" \
  --account-name "$SA_BACKEND" \
  --auth-mode    login

az storage blob list \
  --container-name "tfstate" \
  --account-name   "$SA_BACKEND" \
  --auth-mode    login \
  --output         table

sleep 15

cd terraform

terraform init \
  -backend-config="resource_group_name=${RG_BACKEND}" \
  -backend-config="storage_account_name=${SA_BACKEND}" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${OWNER}.terraform.tfstate" \
  -migrate-state