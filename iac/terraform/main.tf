# ==============================================================================
# TM Forum TMF634 Resource Catalog Bound Terraform Module
# Bound to RFS: 5G_Core_UPF_Infra_RFS (rfs-spec-upf-infra-001)
#   - res-spec-vpc-001 (TelcoVpcNetworkSpec): 1 VPC + 3 Subnets (SGi, N3, N4)
#   - res-spec-netpol-003 (SriovAndEbpfNetworkPolicySpec): GTP-U & PFCP Firewall
#   - res-spec-compute-002 (ComputeFlavorSpec): Workload Identity SA & Secret
# ==============================================================================

# 1. Dedicated Telco UPF VPC Network (res-spec-vpc-001)
resource "google_compute_network" "upf_vpc" {
  name                    = "vpc-upf-${var.tenant_id}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "TMF634 TelcoVpcNetworkSpec (res-spec-vpc-001) provisioned for Order ${var.order_id}"
}

# 2. Subnet 1: SGi / N6 External Data Network Subnet
resource "google_compute_subnetwork" "sgi_subnet" {
  name                     = "sgi-subnet-${var.tenant_id}"
  region                   = var.region
  network                  = google_compute_network.upf_vpc.id
  ip_cidr_range            = var.sgi_subnet_cidr
  private_ip_google_access = true
  description              = "5G Core UPF SGi/N6 External Data Plane Subnet (${var.order_id})"
}

# 3. Subnet 2: N3 5G RAN-to-UPF GTP-U User-Plane Subnet
resource "google_compute_subnetwork" "n3_subnet" {
  name                     = "n3-subnet-${var.tenant_id}"
  region                   = var.region
  network                  = google_compute_network.upf_vpc.id
  ip_cidr_range            = var.n3_subnet_cidr
  private_ip_google_access = true
  description              = "5G Core UPF N3 RAN GTP-U User-Plane Subnet (${var.order_id})"
}

# 4. Subnet 3: N4 SMF-to-UPF PFCP Control-Plane Subnet
resource "google_compute_subnetwork" "n4_subnet" {
  name                     = "n4-subnet-${var.tenant_id}"
  region                   = var.region
  network                  = google_compute_network.upf_vpc.id
  ip_cidr_range            = var.n4_subnet_cidr
  private_ip_google_access = true
  description              = "5G Core UPF N4 SMF PFCP Control-Plane Subnet (${var.order_id})"
}

# 5. Telco 5G UPF Dataplane Firewall Policy (GTP-U UDP/2152 & PFCP UDP/8805)
resource "google_compute_firewall" "upf_dataplane_gtpu_pfcp" {
  name        = "fw-upf-gtpu-pfcp-${var.tenant_id}"
  network     = google_compute_network.upf_vpc.name
  description = "TMF634 SriovAndEbpfNetworkPolicySpec (res-spec-netpol-003) Mode=${var.dataplane_mode}"

  allow {
    protocol = "udp"
    ports    = ["2152", "8805"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_ranges = [
    var.sgi_subnet_cidr,
    var.n3_subnet_cidr,
    var.n4_subnet_cidr
  ]

  target_tags = ["upf-worker-${var.tenant_id}"]
}

# 6. Dedicated GCP Workload Identity Service Account for the UPF Edge Slice
resource "google_service_account" "upf_tenant_sa" {
  account_id   = "upf-${var.tenant_id}-sa"
  display_name = "TMF652 Provisioned UPF Edge Slice SA (${var.tenant_id})"
  description  = "Order ${var.order_id} | Latency=${var.latency_tier} | Dataplane=${var.dataplane_mode}"
}

# 7. Per-Order Secret Manager Record Storing Decomposed RFS/Resource Metadata
resource "google_secret_manager_secret" "upf_slice_secret" {
  secret_id = "tmf652-upf-slice-${var.tenant_id}"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    tenant_id      = var.tenant_id
    rfs_spec       = "rfs-spec-upf-infra-001"
    dataplane_mode = lower(replace(var.dataplane_mode, "-", "_"))
  }
}

resource "google_secret_manager_secret_version" "upf_slice_secret_val" {
  secret = google_secret_manager_secret.upf_slice_secret.id
  secret_data = jsonencode({
    order_id        = var.order_id
    tenant_id       = var.tenant_id
    cfs_spec        = "cfs-spec-private5g-edge-001"
    rfs_spec        = "rfs-spec-upf-infra-001"
    latency_tier    = var.latency_tier
    throughput_tier = var.throughput_tier
    dataplane_mode  = var.dataplane_mode
    cpu_count       = var.cpu_count
    ram_gb          = var.ram_gb
    numa_nodes      = var.numa_nodes
    dpdk_enabled    = var.dpdk_enabled
    subnets = {
      sgi = var.sgi_subnet_cidr
      n3  = var.n3_subnet_cidr
      n4  = var.n4_subnet_cidr
    }
  })
}

resource "google_secret_manager_secret_iam_member" "upf_secret_access" {
  secret_id = google_secret_manager_secret.upf_slice_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.upf_tenant_sa.email}"
}
