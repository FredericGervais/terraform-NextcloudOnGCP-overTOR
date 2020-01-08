# terraform-OwncloudOnGCP

## Installation

```
git clone https://github.com/FredericGervais/terraform-OwncloudOnGCP terraform-Owncloud
cd terraform-Owncloud
terraform init
terraform apply -auto-approve -target=google_sql_database_instance.master -target=google_filestore_instance.instance -target=null_resource.configure_kubectl && terraform apply -auto-approve
```
