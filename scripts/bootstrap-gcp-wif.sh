#!/usr/bin/env bash
# ==============================================================================
# One-Time GCP Bootstrap: Workload Identity Federation (WIF) & GCS State Bucket
# Repository: tmf-federated-catalog-gcp-poc
# ==============================================================================
# If you already ran bootstrap-gcp-wif.sh for the previous PoC in project
# 'gcp-oda-canvas-poc', running this script simply adds the WIF repository binding
# for your new repo (e.g., wipro-gcp-ashu/tmf-federated-catalog-gcp-poc) and
# prints the 5 GitHub Actions variables to copy-paste!
# ==============================================================================

set -euo pipefail

PROJECT_ID="${1:-gcp-oda-canvas-poc}"
GITHUB_REPO="${2:-wipro-gcp-ashu/tmf-federated-catalog-gcp-poc}"
REGION="${3:-us-central1}"

SA_NAME="github-oda-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-oidc-provider"
TF_STATE_BUCKET="${PROJECT_ID}-tfstate"
GITHUB_OWNER="${GITHUB_REPO%%/*}"

echo "=================================================================="
echo " Bootstrapping GCP Project : ${PROJECT_ID}"
echo " GitHub Repository         : ${GITHUB_REPO}"
echo " Region                    : ${REGION}"
echo "=================================================================="

gcloud config set project "${PROJECT_ID}"

# 1. Enable Required APIs
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com

# 2. Ensure GCS Bucket for Terraform Remote State exists
if ! gsutil ls -b "gs://${TF_STATE_BUCKET}" >/dev/null 2>&1; then
  gsutil mb -p "${PROJECT_ID}" -l "${REGION}" -b on "gs://${TF_STATE_BUCKET}"
  gsutil versioning set on "gs://${TF_STATE_BUCKET}"
fi

# 3. Ensure Deployer Service Account exists
if ! gcloud iam service-accounts describe "${SA_EMAIL}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="GitHub Actions ODA & Federated Catalog Deployer"
fi

ROLES=(
  "roles/compute.networkAdmin"
  "roles/compute.securityAdmin"
  "roles/container.admin"
  "roles/iam.serviceAccountAdmin"
  "roles/iam.serviceAccountUser"
  "roles/resourcemanager.projectIamAdmin"
  "roles/secretmanager.admin"
  "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --condition=None \
    --quiet >/dev/null
done

# 4. Ensure Workload Identity Pool & OIDC Provider exist
if ! gcloud iam workload-identity-pools describe "${POOL_NAME}" --location="global" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${POOL_NAME}" \
    --location="global" \
    --display-name="GitHub Actions Pool"
fi

POOL_ID=$(gcloud iam workload-identity-pools describe "${POOL_NAME}" \
  --location="global" \
  --format="value(name)")

if ! gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --workload-identity-pool="${POOL_NAME}" \
  --location="global" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
    --workload-identity-pool="${POOL_NAME}" \
    --location="global" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository_owner == '${GITHUB_OWNER}'"
fi

# 5. Bind the new GitHub Repository to the Service Account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GITHUB_REPO}" \
  --quiet >/dev/null

PROVIDER_RESOURCE_NAME=$(gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --workload-identity-pool="${POOL_NAME}" \
  --location="global" \
  --format="value(name)")

echo ""
echo "=================================================================="
echo " SUCCESS! Add these 5 Repository Variables in your new GitHub repo"
echo " (${GITHUB_REPO} -> Settings -> Secrets and variables -> Actions -> Variables):"
echo "=================================================================="
echo "GCP_PROJECT_ID       = ${PROJECT_ID}"
echo "GCP_REGION           = ${REGION}"
echo "GKE_CLUSTER_NAME     = oda-canvas-mt-gke"
echo "TF_STATE_BUCKET      = ${TF_STATE_BUCKET}"
echo "WIF_PROVIDER         = ${PROVIDER_RESOURCE_NAME}"
echo "WIF_SERVICE_ACCOUNT  = ${SA_EMAIL}"
echo "=================================================================="
