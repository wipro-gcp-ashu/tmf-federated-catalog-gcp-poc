# TM Forum ODA & SID (`GB922`) Federated Catalog & Self-Provisioned Infrastructure PoC on Google Cloud (`TMF620` → `TMF633` → `TMF634` → IaC)

[![TM Forum ODA](https://img.shields.io/badge/TM%20Forum-ODA%20IG1228%20%26%20SID%20GB922-0052CC?style=for-the-badge)](https://www.tmforum.org/oda/)
[![TMF Open APIs](https://img.shields.io/badge/Open%20APIs-TMF620%20%7C%20633%20%7C%20634%20%7C%20622%20%7C%20641%20%7C%20652%20%7C%20638%20%7C%20639-00875A?style=for-the-badge)](https://www.tmforum.org/oda/open-apis/)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-GKE%20%26%20Terraform%20IaC-4285F4?style=for-the-badge&logo=google-cloud)](https://cloud.google.com/)

This repository implements the **Cloud Studio & Google Cloud Platform (GCP) Proof of Concept (PoC)** aligned with **TM Forum Open Digital Architecture (`IG1228`)** and the **Shared Information/Data Model (`GB922` SID)** for **Catalog-Driven Self-Provisioned Infrastructure**.

It demonstrates how telecom operators decouple **commercial intent** from **technical cloud delivery** across a **4-layer federated catalog hierarchy** and execute an automated **Day-0 / Day-1 Order-to-Activation pipeline** (`TMF622` → `TMFC003` → `TMF641` → `TMF652` → Terraform/GKE → `TMF639` & `TMF638` Active Inventory).

---

## 1. Federated Catalog Architecture (`TMF620` → `TMF633` CFS → `TMF633` RFS → `TMF634` → IaC)

```text
[1. Commercial Product Catalog (TMF620 / TMFC001)]
   Entity: ProductOffering ("Enterprise Private Edge Infrastructure Tier 1")
   Entity: ProductSpecification ("prod-spec-edge-infra-t1")
                 │
                 │  (Maps Commercial Offer to Service Intent)
                 ▼
[2. Customer-Facing Service (CFS) Catalog (TMF633 / TMFC006)]
   Entity: CustomerFacingServiceSpecification ("Private5G_Edge_Compute_CFS")
   Inputs: throughput_tier ("10Gbps"), latency_tier ("Ultra-Low"), redundancy ("active-standby")
   Rules : RULE-LATENCY-01 (If latency_tier == "Ultra-Low" ──► NUMA=2, DPDK=true, SR-IOV)
                 │
                 │  (Decomposes via Policy Rules to RFS)
                 ▼
[3. Resource-Facing Service (RFS) Catalog (TMF633 / TMFC006)]
   Entity: ResourceFacingServiceSpecification ("5G_Core_UPF_Infra_RFS")
   Stack : Composes 1 VPC, 3 Telco Subnets (SGi, N3, N4), 1 SR-IOV/eBPF Policy, Storage Pool & 2 Worker Instances
                 │
                 │  (Binds Technical Service to Atomic Cloud Primitives)
                 ▼
[4. Resource Catalog (TMF634 / TMFC007)] ──► Infrastructure as Code (Terraform & Kubernetes/Helm)
   • res-spec-vpc-001     (TelcoVpcNetworkSpec)            ──► iac/terraform/main.tf (VPC + SGi, N3, N4 Subnets)
   • res-spec-compute-002 (ComputeFlavorSpec)              ──► iac/terraform/main.tf + GKE UPF Worker Slice
   • res-spec-netpol-003  (SriovAndEbpfNetworkPolicySpec)  ──► GTP-U (UDP/2152) & PFCP (UDP/8805) + K8s NetworkPolicy
   • res-spec-storage-004 (StoragePoolSpec)                ──► GKE PersistentDisk CSI Volume (premium-rwo / standard-rwo)
```

### 1.1 TM Forum Catalog Layer Mapping Table

| Catalog Layer | TM Forum API | ODA Component | Telecom Domain Role | Repository Artifact |
| :--- | :--- | :--- | :--- | :--- |
| **Product Catalog** | **TMF620** | **TMFC001** | Commercial packaging, SLAs (`99.99%`), flat + usage pricing, ordering eligibility rules | `catalogs/step3-tmf620-product-catalog/prod-offer-enterprise-edge-tier1.json` |
| **Service Catalog (CFS)** | **TMF633** | **TMFC006** | Technology-agnostic capability (`throughput_tier`, `latency_tier`, `redundancy`) + decomposition rules | `catalogs/step2-tmf633-service-catalog/cfs/cfs-spec-private5g-edge-001-Private5G_Edge_Compute_CFS.json` |
| **Service Catalog (RFS)** | **TMF633** | **TMFC006** | Internal operational topology (`5G_Core_UPF_Infra_RFS`: 1 VPC, 3 Subnets `SGi`/`N3`/`N4`, 2 Workers) | `catalogs/step2-tmf633-service-catalog/rfs/rfs-spec-upf-infra-001-5G_Core_UPF_Infra_RFS.json` |
| **Resource Catalog** | **TMF634** | **TMFC007** | Atomic cloud primitives exposing `resourceSpecCharacteristic` inputs & `iac_binding` | `catalogs/step1-tmf634-resource-catalog/*.json` → `iac/terraform/` |

---

## 2. Repository Structure

```text
tmf-federated-catalog-gcp-poc/
├── .github/workflows/
│   ├── 01-publish-federated-catalogs.yml        # Step 1-3: Validate SID hierarchy & publish TMF634/633/620 to GKE
│   ├── 02-day0-day1-order-to-activation.yml     # Day-0/Day-1: TMF622 Order -> TMF641 -> TMF652 -> Terraform/GKE -> TMF638/639 Active
│   └── 99-teardown-order-infra.yml              # Clean teardown of provisioned tenant VPC/Subnets & GKE UPF slice
├── catalogs/
│   ├── step1-tmf634-resource-catalog/           # Step 1: Atomic ResourceSpecifications (TMF634)
│   │   ├── res-spec-vpc-001-TelcoVpcNetworkSpec.json
│   │   ├── res-spec-compute-002-ComputeFlavorSpec.json
│   │   ├── res-spec-netpol-003-SriovAndEbpfNetworkPolicySpec.json
│   │   └── res-spec-storage-004-StoragePoolSpec.json
│   ├── step2-tmf633-service-catalog/            # Step 2: RFS & CFS ServiceSpecifications (TMF633)
│   │   ├── rfs/rfs-spec-upf-infra-001-5G_Core_UPF_Infra_RFS.json
│   │   └── cfs/cfs-spec-private5g-edge-001-Private5G_Edge_Compute_CFS.json
│   └── step3-tmf620-product-catalog/            # Step 3: Commercial ProductSpec & ProductOffering (TMF620)
│       ├── prod-spec-edge-infra-t1.json
│       └── prod-offer-enterprise-edge-tier1.json
├── orders/                                      # Sample TMF622 ProductOrder payloads
│   ├── order-ultralow-tenant-delta.json         # Ultra-Low Latency (10Gbps, active-standby -> NUMA=2, DPDK=true, SR-IOV)
│   └── order-standard-tenant-epsilon.json       # Standard Latency (1Gbps, single-node -> Standard eBPF)
├── orchestrator/                                # Cloud Studio Order Orchestrator (TMFC003) & GKE API Gateway
│   ├── cloud_studio_orchestrator.py             # Decomposition Engine (TMF622 -> TMF641 -> TMF652 -> tfvars -> TMF638/639)
│   └── k8s-tmf-federated-api-gateway.yaml       # Live GKE REST server for TMF620, TMF633, TMF634, TMF638, TMF639
├── iac/
│   └── terraform/                               # Step 1 Bound Terraform Module (provisions 1 VPC + 3 Subnets SGi/N3/N4 + IAM + Secret)
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
└── scripts/
    ├── bootstrap-gcp-wif.sh                     # Binds this repo to GCP Workload Identity Federation in 1 command
    └── run-live-demo.sh                         # Instant CLI demo runner for local or Cloud Shell walkthroughs
```

---

## 3. Quick Start: Push to GitHub & Connect to GCP (`gcp-oda-canvas-poc`)

### Step 1: Create the New GitHub Repository & Push Code
1. On GitHub, create a new empty repository under your account: **`https://github.com/wipro-gcp-ashu/tmf-federated-catalog-gcp-poc`** (do not initialize with a README).
2. From this directory, push the code:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: TM Forum Federated Catalog (TMF620/633/634) & Order-to-Activation GCP PoC"
   git branch -M main
   git remote add origin https://github.com/wipro-gcp-ashu/tmf-federated-catalog-gcp-poc.git
   git push -u origin main
   ```

### Step 2: Bind the New GitHub Repo to Your Existing GCP Workload Identity Pool
In **Google Cloud Shell** (project `gcp-oda-canvas-poc`), run:
```bash
bash scripts/bootstrap-gcp-wif.sh gcp-oda-canvas-poc wipro-gcp-ashu/tmf-federated-catalog-gcp-poc us-central1
```
Then add the printed **Repository Variables** in GitHub (**Settings → Secrets and variables → Actions → Variables**):
- `GCP_PROJECT_ID` = `gcp-oda-canvas-poc`
- `GCP_REGION` = `us-central1`
- `GKE_CLUSTER_NAME` = `oda-canvas-mt-gke`
- `TF_STATE_BUCKET` = `gcp-oda-canvas-poc-tfstate`
- `WIF_PROVIDER` = *(printed by script — same provider as your existing repo)*
- `WIF_SERVICE_ACCOUNT` = `github-oda-deployer@gcp-oda-canvas-poc.iam.gserviceaccount.com`

---

## 4. 10-Minute Live Customer / Manager Demo Runbook

### Demo Part 1: Show the 4-Layer Federated Catalog Hierarchy (3 mins)
1. Open the repository and walk bottom-up through `catalogs/`:
   - **Step 1 (`TMF634` Resource Catalog)**: Open `catalogs/step1-tmf634-resource-catalog/res-spec-compute-002-ComputeFlavorSpec.json` and `res-spec-vpc-001-TelcoVpcNetworkSpec.json`. Point out the `resourceSpecCharacteristic` inputs (`cpu_count`, `ram_gb`, `numa_nodes`, `dpdk_enabled`, `sgi_subnet_cidr`, `n3_subnet_cidr`, `n4_subnet_cidr`) and `iac_binding` pointing to `./iac/terraform`.
   - **Step 2 (`TMF633` Service Catalog — RFS & CFS)**:
     - Open `rfs-spec-upf-infra-001-5G_Core_UPF_Infra_RFS.json` showing how the RFS groups **1 VPC, 3 Subnets (`SGi`, `N3`, `N4`), SR-IOV/eBPF policy, Storage Pool, and 2 Worker instances**.
     - Open `cfs-spec-private5g-edge-001-Private5G_Edge_Compute_CFS.json` showing the customer-facing attributes (`throughput_tier: 10Gbps`, `latency_tier: Ultra-Low`, `redundancy: active-standby`) and **`RULE-LATENCY-01`** (`if cfs.latency_tier == 'Ultra-Low'` → `numa_nodes = 2`, `dpdk_enabled = true`, `dataplane_mode = 'SR-IOV'`).
   - **Step 3 (`TMF620` Product Catalog)**: Open `prod-offer-enterprise-edge-tier1.json` showing commercial packaging, 12-month SLA commitment, and pricing decoupled from technical parameters.
2. In GitHub Actions, trigger **`01 - Publish & Validate TM Forum Federated Catalogs (TMF634 -> TMF633 -> TMF620)`** and show the **100% SID `GB922` Referential Integrity table** generated in the Job Summary.

### Demo Part 2: Trigger Live Day-0 / Day-1 Self-Service Provisioning (5 mins)
1. Go to **GitHub Actions → `02 - Day-0/Day-1 Order-to-Activation Pipeline`** and click **Run workflow**:
   - `tenant_id`: `tenant-delta`
   - `customer_name`: `Delta Manufacturing Corp`
   - `latency_tier`: `Ultra-Low`
   - `throughput_tier`: `10Gbps`
   - `redundancy`: `active-standby`
   - `execution_mode`: `full-gcp-provisioning`
2. Watch the pipeline execute the 7 stages automatically:
   - **Ingests `TMF622` ProductOrder** → **Resolves `TMF620` → `TMF633` CFS** → **Evaluates `RULE-LATENCY-01`** → **Generates `TMF641` ServiceOrder & `TMF652` ResourceOrder**.
   - **Runs Terraform on GCP** to provision the dedicated Telco VPC (`vpc-upf-tenant-delta`), all **3 Telco Subnets (`sgi-subnet-tenant-delta`, `n3-subnet-tenant-delta`, `n4-subnet-tenant-delta`)**, GTP-U/PFCP firewall rules, Workload Identity SA, and Secret Manager credentials, plus deploys the UPF worker slice to GKE (`upf-tenant-delta`).
   - **Populates real GCP resource `self_link` URIs and Kubernetes UIDs back into `TMF639` Resource Inventory** and transitions both **`TMF638` Service Inventory** and **`TMF639` Resource Inventory** to `Active`!

### Demo Part 3: Inspect the Live GCP Resources & Active Inventory Payloads (2 mins)
1. Open the completed GitHub Actions Job Summary to show:
   - The **Federated Catalog Decomposition Trace Table**.
   - The **Active Physical Resource Inventory Table (`TMF639`)** containing real GCP VPC and `SGi`/`N3`/`N4` subnet self-links.
   - Expandable JSON blocks for `TMF641 ServiceOrder`, `TMF652 ResourceOrder`, `TMF639 Resource Inventory`, and `TMF638 Service Inventory`.
2. Optionally run locally or in Cloud Shell at any time:
   ```bash
   bash scripts/run-live-demo.sh
   ```
