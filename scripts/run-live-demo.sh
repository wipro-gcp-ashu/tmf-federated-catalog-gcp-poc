#!/usr/bin/env bash
# ==============================================================================
# Interactive Live Demo Runner: TM Forum Federated Catalog & Order-to-Activation
# ==============================================================================
set -euo pipefail

echo "================================================================================"
echo " STEP 1-3: Validating 4-Layer TM Forum Federated Catalog Hierarchy (GB922 SID)"
echo "   [TMF620 Product] -> [TMF633 CFS] -> [TMF633 RFS] -> [TMF634 Resource -> IaC]"
echo "================================================================================"
python3 orchestrator/cloud_studio_orchestrator.py --mode validate-catalogs

echo ""
echo "================================================================================"
echo " DAY-0 / DAY-1 PIPELINE DEMO: Ingesting TMF622 ProductOrder (ORD-2026-EDGE-9001)"
echo "   Customer     : Delta Manufacturing Corp (tenant-delta)"
echo "   Offering     : Enterprise Private Edge Infrastructure Tier 1 (TMF620)"
echo "   CFS Intent   : throughput_tier=10Gbps | latency_tier=Ultra-Low | active-standby"
echo "================================================================================"
python3 orchestrator/cloud_studio_orchestrator.py \
  --mode decompose \
  --order-file orders/order-ultralow-tenant-delta.json \
  --project-id "${GCP_PROJECT_ID:-gcp-oda-canvas-poc}"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Generated Terraform Variables (iac/terraform/generated.auto.tfvars.json):"
echo "--------------------------------------------------------------------------------"
cat iac/terraform/generated.auto.tfvars.json

echo ""
echo "================================================================================"
echo " STATE SYNCHRONIZATION: Updating TMF639 Resource & TMF638 Service Inventory"
echo "================================================================================"
python3 orchestrator/cloud_studio_orchestrator.py \
  --mode sync-inventory \
  --tf-outputs-json "build/tf-outputs.json" \
  --k8s-namespace-uid "ns-upf-tenant-delta-9f82a1c4" \
  --k8s-pod-uids "pod-upf-worker-0-a81c,pod-upf-worker-1-b92d" \
  --gke-cluster-name "oda-canvas-mt-gke"
