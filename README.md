# EKS Cluster Provisioning with Terraform

EKS cluster provisioned via Terraform with CI/CD pipeline and bastion host access.

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
│   └── NAT Gateway
├── Private Subnets (10.0.3.0/24, 10.0.4.0/24)
│   ├── EKS Worker Nodes
│   └── Bastion Host (SSM access)
├── VPC Endpoints (SSM, SSMMessages, EC2Messages)
└── Internet Gateway

EKS Cluster: Private API endpoint only
```

## Repository Structure

```
.
├── main.tf                 # Root module
├── variables.tf            # Input variables
├── outputs.tf              # Cluster and bastion outputs
├── versions.tf             # Terraform & AWS provider versions + default tags
├── backend.tf              # S3 remote backend + DynamoDB locking
├── terraform.tfvars        # Non-sensitive variable overrides
├── modules/
│   ├── eks/
│   │   ├── main.tf         # VPC, subnets, NAT GW, EKS cluster, node group
│   │   ├── variables.tf    # Module input variables
│   │   ├── outputs.tf      # Module outputs
│   │   └── versions.tf     # Module version constraints
│   └── bastion/
│       ├── main.tf         # Bastion EC2, IAM role, VPC endpoints for SSM
│       ├── variables.tf    # Module input variables
│       ├── outputs.tf      # Module outputs
│       └── versions.tf     # Module version constraints
├── k8s/
│   └── nginx-pod.yaml      # Nginx test pod + service
└── .github/
    ├── workflows/
    │   └── terraform.yml   # CI/CD pipeline
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

## Connect to Bastion Host

Connect via AWS Systems Manager (no SSH required):

```bash
# Get bastion instance ID from Terraform output
BASTION_ID=$(terraform output -raw bastion_instance_id)

# Start SSM session
aws ssm start-session --target $BASTION_ID --region eu-central-1
```

## Configure Cluster Access (from Bastion)

Once connected to bastion via SSM:

```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-central-1 --name minimal-eks-cluster

# Verify access
kubectl cluster-info
kubectl get nodes
```

## Deploy Test Pod

From the bastion host:

```bash
kubectl apply -f k8s/nginx-pod.yaml
kubectl get pods
kubectl get svc
```

### Validate HTTP Connection
```bash
kubectl port-forward pod/nginx-test 8080:80 &
curl http://localhost:8080
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

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | eu-central-1 | AWS region |
| `cluster_name` | minimal-eks-cluster | EKS cluster name |
| `node_instance_type` | t3.small | EC2 instance type for nodes |
| `desired_capacity` | 1 | Number of worker nodes |
| `bastion_instance_type` | t3.micro | EC2 instance type for bastion |

## Tags

All resources are tagged via provider `default_tags` (DRY):
- `Project: static-website`
- `ManagedBy: terraform`

## Reflection: Why Private Networking?

Using private addressing and keeping cluster nodes without public IPs is a DevOps best practice because:

1. **Reduced Attack Surface**: Nodes without public IPs cannot be directly accessed from the internet, eliminating a major attack vector.

2. **Defense in Depth**: Multiple security layers (private subnets, NAT Gateway, security groups, VPC endpoints) provide layered protection.

3. **Compliance Requirements**: Many regulatory frameworks (PCI-DSS, HIPAA, SOC2) require workloads to run in private network segments.

4. **Network Segmentation**: Clear separation between public-facing resources and internal workloads limits blast radius of potential breaches.

5. **Controlled Egress**: All outbound traffic routes through NAT Gateway, enabling centralized logging, monitoring, and filtering of external connections.

6. **Least Privilege Access**: Access to the cluster requires explicit bastion connection via SSM, creating an auditable access path.
