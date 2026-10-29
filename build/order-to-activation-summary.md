## 🚀 Day-0 / Day-1 Order-to-Activation Execution Summary (`ORD-2026-EDGE-9001`)

### 1. Federated Catalog Decomposition Trace (`TMF620` → `TMF633` CFS → `TMF633` RFS → `TMF634` → IaC)

| Pipeline Stage | TM Forum Open API | Entity / Artifact ID | Resolved Configuration & Policy Output | State |
| :--- | :--- | :--- | :--- | :--- |
| **1. Commercial Order** | `TMF622` (`TMFC002`) | `ORD-2026-EDGE-9001` (`prod-offer-enterprise-edge-tier1`) | Tenant: `tenant-delta`, Throughput: `10Gbps`, Latency: `Ultra-Low` | `Completed` |
| **2. CFS Orchestration** | `TMF633` / `TMF641` | `cfs-spec-private5g-edge-001` (`Private5G_Edge_Compute_CFS`) | Evaluated `3` policy rules (`RULE-LATENCY-01`, `RULE-THROUGHPUT-02`, `RULE-HA-03`) | `Active` (`TMF638`) |
| **3. RFS Orchestration** | `TMF633` / `TMF641` | `rfs-spec-upf-infra-001` (`5G_Core_UPF_Infra_RFS`) | `1 VPC`, `3 Subnets (SGi, N3, N4)`, `worker_instances=2`, `dataplane=SR-IOV` | `Active` (`TMF638`) |
| **4. Resource & IaC Execution** | `TMF634` / `TMF652` | `res-spec-vpc-001`, `res-spec-compute-002`, `res-spec-netpol-003`, `res-spec-storage-004` | `cpu=16`, `ram=64GiB`, `numa_nodes=2`, `dpdk_enabled=True` | `Active` (`TMF639`) |

---

### 2. Active Physical Resource Inventory (`TMF639` — Populated from Live GCP & GKE State)

| Resource Characteristic | Physical Cloud / Kubernetes Identifier (`TMF639`) |
| :--- | :--- |
| **GCP Project ID** | `gcp-oda-canvas-poc` |
| **Telco UPF VPC (`res-spec-vpc-001`)** | `projects/gcp-oda-canvas-poc/global/networks/vpc-upf-tenant-delta` |
| **SGi External Data Subnet (`SGi`)** | `projects/gcp-oda-canvas-poc/regions/us-central1/subnetworks/sgi-subnet-tenant-delta` (`10.160.1.0/24`) |
| **5G RAN GTP-U User-Plane Subnet (`N3`)** | `projects/gcp-oda-canvas-poc/regions/us-central1/subnetworks/n3-subnet-tenant-delta` (`10.160.2.0/24`) |
| **SMF PFCP Control-Plane Subnet (`N4`)** | `projects/gcp-oda-canvas-poc/regions/us-central1/subnetworks/n4-subnet-tenant-delta` (`10.160.3.0/24`) |
| **GKE Cluster & UPF Slice Namespace** | `oda-canvas-mt-gke` / Namespace: `upf-tenant-delta` (UID: `ns-upf-delta-9f82a1c4`) |
| **UPF Worker Pod UIDs (`res-spec-compute-002`)** | `pod-upf-0,pod-upf-1` |
| **Workload Identity IAM Service Account** | `upf-tenant-delta-sa@gcp-oda-canvas-poc.iam.gserviceaccount.com` |
