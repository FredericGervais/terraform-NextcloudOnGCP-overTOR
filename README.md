# terraform-OwncloudOnGCP

## Prerequisite

Once in your [GCP Cloud Shell](https://console.cloud.google.com/home/dashboard?cloudshell=true), be sure to be connected to your project you want to deploy this solution too.

You can specify the project to connect to with this command:
```
gcloud config set project [YourProjectName]
```

Run this to download the files necessary for the installation
```
git clone https://github.com/FredericGervais/terraform-OwncloudOnGCP terraform-OwncloudOnGCP
cd terraform-OwncloudOnGCP
terraform init
```

You now need to place the [Service Account key .json file](https://learn.hashicorp.com/terraform/gcp/build) in the current folder beside the .tf files under the name:
> credential.json

## Installation

To install Owncloud you now need to run this command:
```
terraform apply -auto-approve -target=google_sql_database_instance.master -target=google_filestore_instance.instance -target=null_resource.configure_kubectl && terraform apply -auto-approve
```
