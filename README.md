# terraform-NextcloudOnGCP-overTOR

This is a Terraform script that installs Nextcloud in a GCP Project. It uses these products:  
- Network  
- Filestore  
- Cloud SQL  
- GKE cluster  
- Nextcloud docker image  
- goldy/tor-hidden-service docker image  

## Prerequisite

Once in your [GCP Cloud Shell](https://console.cloud.google.com/home/dashboard?cloudshell=true), be sure to be connected to your project you want to deploy this solution too.

You can specify the project to connect to with this command:
```
gcloud config set project [YourProjectName]
```

Run this to download the files necessary for the installation
```
git clone https://github.com/FredericGervais/terraform-NextcloudOnGCP-overTOR terraform-NextcloudOnGCP-overTOR
cd terraform-NextcloudOnGCP-overTOR
terraform init
```

You now need to place the [Service Account key .json file](https://learn.hashicorp.com/terraform/gcp/build) in the current folder beside the .tf files under the name:
> credential.json

**Make sure the terraform service account has the Project Owner role**

## Installation

To install Nextcloud you now need to run this command:
```
terraform apply -auto-approve -target=null_resource.configure_kubectl && terraform apply -auto-approve -refresh=false
```

## Usage

Once the script finishes, you should see a Terraform output specifying the url to access the site.  
Example :
> Website_Public_Address = cloudxwou5tzhbgb.onion
