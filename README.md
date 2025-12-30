# EKS Cluster Provisioning with Terraform

Minimal EKS cluster provisioned via Terraform with CI/CD pipeline (GitHub Actions).

## Repository Structure

```
.
├── main.tf                 # Root module - calls EKS module
├── variables.tf            # Input variables with defaults
├── outputs.tf              # Cluster outputs (endpoint, name, CA cert)
├── versions.tf             # Terraform & AWS provider versions + default tags
├── backend.tf              # S3 remote backend + DynamoDB locking
├── terraform.tfvars        # Non-sensitive variable overrides
├── modules/
│   └── eks/
│       ├── main.tf         # VPC, EKS cluster, node group, IAM roles
│       ├── variables.tf    # Module input variables
│       ├── outputs.tf      # Module outputs
│       └── versions.tf     # Module version constraints
├── k8s/
│   └── nginx-pod.yaml      # Nginx test pod + service manifest
└── .github/
    ├── workflows/
    │   └── terraform.yml   # CI/CD pipeline (plan/apply/destroy)
    └── IAM-CICD/
        └── main.tf         # GitHub Actions IAM roles (OIDC)
```

## Prerequisites

### 1. Create S3 Backend for Terraform State
```bash
aws s3api create-bucket \
  --bucket cluster-provisioning-2115-tfstate \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket cluster-provisioning-2115-tfstate \
  --versioning-configuration Status=Enabled
```

### 2. Create DynamoDB Table for State Locking
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 3. Setup GitHub Actions IAM Roles
```bash
cd .github/IAM-CICD
terraform init
terraform apply
```
Add the output ARNs as GitHub repository secrets:
- `AWS_PLAN_ROLE_ARN`
- `AWS_APPLY_ROLE_ARN`

### Deploy via CI/CD

**Plan Stage (Pull Request):**
1. Create feature branch and push changes
2. Open PR to `main` branch
3. Pipeline runs: `fmt -check` → `init` → `validate` → `plan`
4. Plan output uploaded as artifact
5. Review plan before merging

**Apply Stage (Merge to main):**
1. Merge PR to `main`
2. Pipeline runs: `init` → `apply -auto-approve`
3. Infrastructure deployed

### Manual Workflow Dispatch
Go to Actions → Terraform → Run workflow:
- `plan` - Run terraform plan only
- `apply` - Apply infrastructure changes
- `destroy` - Destroy all infrastructure

## Configure Cluster Access

After apply succeeds:
```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name minimal-eks-cluster

kubectl cluster-info
kubectl get nodes
```

## Deploy Test Pod

```bash
kubectl apply -f k8s/nginx-pod.yaml
kubectl get pods
kubectl get svc
```

### Validate HTTP Connection
```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://nginx-test-service:80
```

## Cleanup

### 1. Delete Kubernetes Resources
```bash
kubectl delete -f k8s/nginx-pod.yaml
```

### 2. Destroy Infrastructure via CI/CD
Go to Actions → Terraform → Run workflow → Select `destroy`

### 3. Cleanup State Resources (after project completion)
```bash
aws s3 rb s3://cluster-provisioning-2115-tfstate --force
aws dynamodb delete-table --table-name terraform-state-lock --region eu-central-1
```
