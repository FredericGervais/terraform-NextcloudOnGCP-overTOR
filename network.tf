#
# Dependance:
#
# Sub-Dependance:
#   resource "null_resource" "export-custom-routes" : google_sql_database_instance.master
#
#

resource "google_compute_network" "private_network" {
  provider = google-beta

  name = var.network-name
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.private_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "null_resource" "export-custom-routes" {
  provisioner "local-exec" {
    command = "gcloud compute networks peerings update cloudsql-mysql-googleapis-com --network ${var.network-name} --export-custom-routes --project ${google_sql_database_instance.master.project}"
  }
}

