# Azure Infrastructure Terraform Repository

This repository contains an Azure infrastructure deployment managed with Terraform. It is designed for a training or lab environment where shared Azure resources and a pre-existing resource group are used.

## Repository Structure

- `.github/workflows/terraform.yml` - GitHub Actions workflow that validates, plans, applies, and destroys Terraform infrastructure.
- `deploy-remote-state-storage.sh` - Optional helper script for provisioning the backend storage account and container used by Terraform remote state.
- `terraform/` - Terraform configuration directory.
  - `backend.tf` - Configures the Azure RM backend for state storage.
  - `main.tf` - Root module that instantiates the submodules and manages shared state.
  - `outputs.tf` - Exposes outputs such as application URLs and storage account name.
  - `providers.tf` - Terraform provider configuration.
  - `terraform.tfvars` - Local variable values for training use.
  - `terraform.tfvars.example` - Example variables file.
  - `variables.tf` - Root module input variables.
  - `terraform.tfstate` / `terraform.tfstate.backup` - Local state files (should generally not be committed for production).
- `terraform/modules/` - Reusable module implementations.
  - `app-service/` - App Service module.
  - `function-app/` - Function App module.
  - `container/` - Azure Container Instance module.
  - `network/` - Network module.
  - `storage/` - Storage Account module.

## Purpose

This repository is intended to manage Azure resources through Terraform, including:

- Storage account creation
- App Service deployment
- Function App deployment
- Container Instance deployment
- Network resources

The root module wires these modules together and uses shared data sources for an existing resource group and App Service plan.

## CI / GitHub Actions Workflow

The repository workflow is defined in `.github/workflows/terraform.yml`. It is configured for the `main` branch and supports pull request and push events.

> Note: direct push to `main` is not permitted in this repository. The `push` event is intended to run after an approved change is merged into `main`.

### When jobs run

- `pull_request` against `main`
  - `tflint` - Terraform linting
  - `checkov` - Security scanning
  - `tftest` - `terraform test`
  - `plan` - `terraform plan`

- `push` to `main`
  - `tflint`
  - `checkov`
  - `tftest`
  - `plan`
  - `apply` - Terraform apply runs only on pushes to `main` after changes are merged

- `workflow_dispatch` manual trigger
  - Supports a required `action` input with the option `destroy`
  - When `action: destroy` is selected, the workflow performs an infrastructure teardown via the `destroy` job

### Job dependencies and conditions

- `tflint` runs first, validating HCL formatting and lint rules.
- `checkov` runs in parallel to detect security and compliance issues.
- `tftest` depends on both `tflint` and `checkov` and runs Terraform tests.
- `plan` depends on `tftest` and runs Terraform init, validate, and plan.
- `apply` depends on `plan` and only runs for pushes to `refs/heads/main`.
- `destroy` is only available through manual workflow dispatch and requires choosing the `destroy` action.

### Additional workflow details

- The workflow excludes `dependabot[bot]` from `tflint`, `checkov`, `tftest`, and `plan`.
- The workflow uses Azure OIDC authentication for login and remote state backend access.
- The plan step posts a Markdown comment to pull requests with the Terraform plan summary.

## Azure Backend and Environment Variables

Terraform is configured to use the Azure RM backend. The backend settings are provided dynamically in CI through `-backend-config` parameters.

Required environment settings (set as GitHub secrets or variables):

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `TF_RGROUP` (Azure Resource Group name)
- `TF_SA_BACKEND` (Storage account name for remote state)
- `TF_OWNER` (owner identity used to generate the state key)

In CI, the following environment variables are also injected:

- `ARM_CLIENT_ID`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`
- `ARM_USE_OIDC`
- `RGROUP`
- `SA_BACKEND`
- `OWNER`
- `TF_VAR_owner`
- `TF_VAR_resource_group_name`

## Local workflow

To work locally, copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and update values for your environment. Do not commit secrets.

Example commands:

```bash
cd terraform
terraform init -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<storage>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<owner>.terraform.tfstate"
terraform validate
terraform plan
terraform apply -auto-approve
```

## Notes

- The root module references existing infrastructure for the training environment.
- The shared App Service plan is expected to exist in a separate resource group.
- Adjust module input variables and tags as needed for the intended Azure environment.

## License

This repository does not specify a license. Add a `LICENSE` file if you want to make reuse terms explicit.
