output "upf_vpc_self_link" {
  description = "Physical GCP VPC Self-Link populated into TMF639 Resource Inventory"
  value       = google_compute_network.upf_vpc.self_link
}

output "sgi_subnet_self_link" {
  description = "Physical GCP SGi Subnet Self-Link populated into TMF639 Resource Inventory"
  value       = google_compute_subnetwork.sgi_subnet.self_link
}

output "n3_subnet_self_link" {
  description = "Physical GCP N3 Subnet Self-Link populated into TMF639 Resource Inventory"
  value       = google_compute_subnetwork.n3_subnet.self_link
}

output "n4_subnet_self_link" {
  description = "Physical GCP N4 Subnet Self-Link populated into TMF639 Resource Inventory"
  value       = google_compute_subnetwork.n4_subnet.self_link
}

output "workload_identity_sa_email" {
  description = "Physical GCP IAM Service Account Email populated into TMF639 Resource Inventory"
  value       = google_service_account.upf_tenant_sa.email
}

output "secret_manager_id" {
  description = "Physical GCP Secret Manager ID populated into TMF639 Resource Inventory"
  value       = google_secret_manager_secret.upf_slice_secret.id
}
