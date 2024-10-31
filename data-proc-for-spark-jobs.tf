# Infrastructure for Yandex Data Processing cluster with NAT gateway
#
# RU: https://cloud.yandex.ru/docs/data-proc/tutorials/configure-network
# EN: https://cloud.yandex.com/en-ru/docs/data-proc/tutorials/configure-network

# Specify the following settings:
locals {
  folder_id   = "" # Cloud folder ID, the same as for the provider
  dp_ssh_key  = "" # Absolute path to the SSH public key for the Yandex Data Processing cluster. Example: "~/.ssh/key.pub"

  # The following settings are predefined. Change them only if necessary.
  network_name           = "data-proc_network" # Name of the network
  nat_name               = "nat-gateway" # Name of the NAT gateway
  routing_table_name     = "data-proc-routing-table" # Name of the routing table
  subnet_name            = "data-proc-subnet-a" # Name of the subnet
  security_group_name    = "data-proc-security-group" # Name of the security group
  data_proc_sa_name      = "data-proc-sa" # Name of the service account to manage the Yandex Data Processing cluster
  bucket_name            = "data-proc-bucket" # Set a unique bucket name
  data_proc_cluster_name = "data-proc-cluster" # Name of the Yandex Data Processing cluster
  data_proc_version      = "2.0" # Version of the Yandex Data Processing cluster
}

resource "yandex_vpc_network" "data-proc-network" {
  description = "Network for the Yandex Data Processing cluster"
  name        = local.network_name
}

# NAT gateway for Yandex Data Processing
resource "yandex_vpc_gateway" "nat-gateway" {
  name = local.nat_name
  shared_egress_gateway {}
}

# Routing table for Yandex Data Processing
resource "yandex_vpc_route_table" "data-proc-routing-table" {
  name       = local.routing_table_name
  network_id = yandex_vpc_network.data-proc-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}

resource "yandex_vpc_subnet" "data-proc-subnet" {
  description    = "Subnet for the Yandex Data Processing cluster"
  name           = local.subnet_name
  network_id     = yandex_vpc_network.data-proc-network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-a"
  route_table_id = yandex_vpc_route_table.data-proc-routing-table.id
}

resource "yandex_vpc_security_group" "data-proc-security-group" {
  description = "Security group for the Yandex Data Processing cluster"
  name        = local.security_group_name
  network_id  = yandex_vpc_network.data-proc-network.id

  ingress {
    description       = "The rule allows any incoming traffic within the security group"
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  egress {
    description       = "The rule allows any outgoing traffic within the security group"
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "self_security_group"
  }

  ingress {
    description    = "The rule allows any incoming traffic to the SSH port from any IP address"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "The rule allows connections to the HTTPS port from any IP address"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "The rule allows connections to the HTTP port from any IP address"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a service account
resource "yandex_iam_service_account" "data-proc-sa" {
  folder_id = local.folder_id
  name      = local.data_proc_sa_name
}

# Assign the "dataproc.agent" role to the Yandex Data Processing service account
resource "yandex_resourcemanager_folder_iam_member" "sa-dataproc-agent" {
  folder_id = local.folder_id
  role      = "dataproc.agent"
  member    = "serviceAccount:${yandex_iam_service_account.data-proc-sa.id}"
}

# Assign the "dataproc.provisioner" role to the Yandex Data Processing service account
resource "yandex_resourcemanager_folder_iam_member" "sa-dataproc-provisioner" {
  folder_id = local.folder_id
  role      = "dataproc.provisioner"
  member    = "serviceAccount:${yandex_iam_service_account.data-proc-sa.id}"
}

# Assign the "storage.admin" role to the Yandex Data Processing service account
resource "yandex_resourcemanager_folder_iam_member" "sa-storage-admin" {
  folder_id = local.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.data-proc-sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  description        = "Static access key for the Object Storage bucket"
  service_account_id = yandex_iam_service_account.data-proc-sa.id
}

# Create a bucket
resource "yandex_storage_bucket" "data-proc-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = local.bucket_name
  grant {
    id          = yandex_iam_service_account.data-proc-sa.id
    type        = "CanonicalUser"
    permissions = ["READ", "WRITE"]
  }
}

resource "yandex_dataproc_cluster" "data-proc-cluster" {
  description        = "Yandex Data Processing cluster"
  name               = local.data_proc_cluster_name
  service_account_id = yandex_iam_service_account.data-proc-sa.id
  zone_id            = "ru-central1-a"
  bucket             = local.bucket_name

  security_group_ids = [
    yandex_vpc_security_group.data-proc-security-group.id
  ]

  cluster_config {
    version_id = local.data_proc_version

    hadoop {
      services = ["HDFS", "YARN", "SPARK", "MAPREDUCE", "HIVE"]
      ssh_public_keys = [
        file(local.dp_ssh_key)
      ]
    }

    subcluster_spec {
      name             = "subcluster-master"
      role             = "MASTERNODE"
      subnet_id        = yandex_vpc_subnet.data-proc-subnet.id
      hosts_count      = 1
      assign_public_ip = true

      resources {
        resource_preset_id = "s1.small"    # 4 vCPU Intel Broadwell, 16 GB RAM
        disk_type_id       = "network-ssd" # Fast network SSD storage
        disk_size          = 120           # GB
      }
    }

    subcluster_spec {
      name             = "subcluster-data"
      role             = "DATANODE"
      subnet_id        = yandex_vpc_subnet.data-proc-subnet.id
      hosts_count      = 1
      assign_public_ip = true

      resources {
        resource_preset_id = "s1.small"    # 4 vCPU Intel Broadwell, 16 GB RAM
        disk_type_id       = "network-ssd" # Fast network SSD storage
        disk_size          = 120           # GB
      }
    }
  }
}
