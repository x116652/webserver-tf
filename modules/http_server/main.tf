# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


locals {
  network = "${element(split("-", var.subnet), 0)}"
}

resource "google_compute_instance" "http_server" {
  project      = "${var.project}"
  zone         = "us-west1-a"
  name         = "${local.network}-apache2-instance"
  machine_type = "f1-micro"

  labels = {
    patchgrp = "linuxgrp1"
    mgnd = "mds"
  }

 # Service Account IAM Policy Binding
data "google_compute_default_service_account" "default" {
}

resource "google_service_account" "sa" {
  account_id   = "my-service-account"
  display_name = "A service account for SA use"
}

resource "google_service_account_iam_member" "admin-account-iam" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:ronaldo.ramos@telusinternational.com"
}

# Allow SA service account use the default GCE account
resource "google_service_account_iam_member" "gce-default-account-iam" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa.email}"
} 

  metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '<html><body><h1>This is a demo webserver.</h1><h2>Environment: ${local.network}</h2><p>RR is here!! from rr-local-branch</p></body></html>' | sudo tee /var/www/html/index.html"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${var.subnet}"

    access_config {
      # Include this section to give the VM an external ip address
    }
  }

  # Apply the firewall rule to allow external IPs to access this instance
  tags = ["http-server"]
}
