# terraform-OwncloudOnGCP

## Installation

```
git clone https://github.com/FredericGervais/terraform-OwncloudOnGCP terraform-OwncloudOnGCP
cd terraform-OwncloudOnGCP
terraform init
```

You now need to place the [Service Account key .json file](https://learn.hashicorp.com/terraform/gcp/build) in the current folder beside the .tf files under the name:
> credential.json
```
terraform apply -auto-approve -target=google_sql_database_instance.master -target=google_filestore_instance.instance -target=null_resource.configure_kubectl && terraform apply -auto-approve
```
