#
# Set the variables
#
#

variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type    = string
  default = "us-east1-b"
}

variable "app-name" {
  type    = string
  default = "nextcloud"
}

variable "onion-address" {
  type    = string
  default = "cloud"
}

provider "google" {
  credentials = file("credential.json")

  region = "var.region"
  zone   = "var.zone"
}

provider "google-beta" {
  credentials = file("credential.json")

  region = "var.region"
  zone   = "var.zone"
}

variable "network-name" {
  type    = string
  default = "terraform-network"
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_id" "db_user_password" {
  byte_length = 20
}

resource "random_id" "cluster_name_suffix" {
  byte_length = 4
}

resource "random_id" "nextcloud_admin_user" {
  byte_length = 4
}

variable "nextcloud_admin_user" {
  type    = string
  default = "admin"
}

resource "random_id" "nextcloud_admin_password" {
  byte_length = 20
}