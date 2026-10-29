variable "project_id" {
  description = "GCP Project ID hosting the TM Forum Federated Catalog & ODA Canvas PoC"
  type        = string
  default     = "gcp-oda-canvas-poc"
}

variable "region" {
  description = "Target GCP region (derived from TMF634 ResourceSpecification)"
  type        = string
  default     = "us-central1"
}

variable "tenant_id" {
  description = "Unique tenant identifier passed from TMF622 ProductOrder"
  type        = string
  default     = "tenant-delta"
}

variable "order_id" {
  description = "TMF622 ProductOrder externalId"
  type        = string
  default     = "ORD-2026-EDGE-9001"
}

variable "sgi_subnet_cidr" {
  description = "SGi / N6 External Data Network Subnet CIDR (res-spec-vpc-001)"
  type        = string
  default     = "10.40.1.0/24"
}

variable "n3_subnet_cidr" {
  description = "N3 5G RAN GTP-U User-Plane Subnet CIDR (res-spec-vpc-001)"
  type        = string
  default     = "10.40.2.0/24"
}

variable "n4_subnet_cidr" {
  description = "N4 SMF PFCP Control-Plane Subnet CIDR (res-spec-vpc-001)"
  type        = string
  default     = "10.40.3.0/24"
}

variable "latency_tier" {
  description = "CFS latency_tier characteristic (Standard | Ultra-Low)"
  type        = string
  default     = "Ultra-Low"
}

variable "throughput_tier" {
  description = "CFS throughput_tier characteristic (1Gbps | 10Gbps | 40Gbps)"
  type        = string
  default     = "10Gbps"
}

variable "dataplane_mode" {
  description = "Decomposed TMF634 dataplane_mode (Cilium-eBPF | SR-IOV)"
  type        = string
  default     = "SR-IOV"
}

variable "cpu_count" {
  description = "Decomposed TMF634 ComputeFlavorSpec vCPU count"
  type        = number
  default     = 16
}

variable "ram_gb" {
  description = "Decomposed TMF634 ComputeFlavorSpec RAM in GiB"
  type        = number
  default     = 64
}

variable "numa_nodes" {
  description = "Decomposed TMF634 ComputeFlavorSpec NUMA node count"
  type        = number
  default     = 2
}

variable "dpdk_enabled" {
  description = "Decomposed TMF634 ComputeFlavorSpec DPDK toggle"
  type        = bool
  default     = true
}

variable "worker_instances" {
  description = "Decomposed RFS worker instance replica count"
  type        = number
  default     = 2
}
