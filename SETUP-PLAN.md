# EKS Basic Cluster Setup Plan

## Overview

This guide walks through provisioning a minimal AWS EKS cluster and deploying a test nginx pod to validate the cluster setup. This is the first step in a real-world DevOps project: from cluster creation to validating that workloads can be safely deployed.

---

## Prerequisites

Before starting, ensure you have the following installed and configured:

- **AWS CLI** (v2.x recommended) - configured with appropriate credentials
- **kubectl** - Kubernetes command-line tool
- **eksctl** - Official CLI tool for Amazon EKS

### Install Prerequisites

```bash
# Install AWS CLI (if not installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installations
aws --version
kubectl version --client
eksctl version
```

### Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region (eu-central-1), and output format (json)
```

---

## Step-by-Step Implementation

### Stage 1: Provision EKS Cluster

Create a minimal EKS cluster with 1 node (cost-effective for validation).

```bash
# Create minimal EKS cluster
eksctl create cluster \
  --name eks-test-cluster \
  --region eu-central-1 \
  --nodegroup-name test-nodes \
  --node-type t3.small \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 1 \
  --managed

# This process takes approximately 15-20 minutes
```

**Alternative: Using a config file**

```bash
eksctl create cluster -f eksctl-cluster-config.yaml
```

---

### Stage 2: Configure Access to the Cluster

After cluster creation, eksctl automatically configures kubeconfig. Verify the setup:

```bash
# Update kubeconfig (if needed)
aws eks update-kubeconfig --region eu-central-1 --name eks-test-cluster

# Verify cluster connection
kubectl cluster-info

# Check nodes are ready
kubectl get nodes

# Verify all system pods are running
kubectl get pods -n kube-system
```

**Expected output:**
- Kubernetes control plane should be running
- At least 1 node in `Ready` state
- System pods (coredns, kube-proxy, aws-node) should be `Running`

---

### Stage 3: Create a Simple HTTP Test Pod

Deploy an nginx pod to test the cluster functionality.

```bash
# Apply the nginx test pod configuration
kubectl apply -f nginx-test-pod.yaml

# Watch the pod status
kubectl get pods -w
```

**What the deployment includes:**
- A single nginx pod with port 80 exposed
- Resource limits for safe testing
- A ClusterIP service for internal access

---

### Stage 4: Validate the Setup End-to-End

#### Check Pod Status

```bash
# Verify pod is running
kubectl get pods -o wide

# Check pod details
kubectl describe pod nginx-test

# View pod logs
kubectl logs nginx-test
```

#### Test HTTP Connectivity

**Option A: Port Forwarding (Recommended for testing)**

```bash
# Forward local port 8080 to pod port 80
kubectl port-forward pod/nginx-test 8080:80

# In another terminal, test the connection
curl http://localhost:8080
```

**Option B: Test from another pod**

```bash
# Run a temporary curl pod
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://nginx-test-service:80

# Or use busybox
kubectl run busybox --image=busybox --rm -it --restart=Never -- wget -qO- http://nginx-test-service:80
```

**Expected Result:** You should see the nginx welcome page HTML.

---

### Stage 5: Clean Up

**Important:** Always clean up resources to avoid unnecessary AWS costs.

#### Delete Test Resources

```bash
# Delete the pod and service
kubectl delete -f nginx-test-pod.yaml

# Verify resources are deleted
kubectl get pods
kubectl get services
```

#### Delete the EKS Cluster

```bash
# Delete the entire cluster (this removes all resources)
eksctl delete cluster --name eks-test-cluster --region eu-central-1

# This process takes approximately 10-15 minutes
```

#### Verify Cleanup

```bash
# Check that cluster is deleted
eksctl get cluster --region eu-central-1

# Verify no lingering resources in AWS Console:
# - EC2 instances
# - VPCs (eksctl creates a dedicated VPC)
# - NAT Gateways
# - Elastic IPs
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `kubectl` cannot connect | Run `aws eks update-kubeconfig --region eu-central-1 --name eks-test-cluster` |
| Pod stuck in `Pending` | Check node capacity: `kubectl describe pod <pod-name>` |
| Pod stuck in `ContainerCreating` | Check events: `kubectl get events --sort-by='.lastTimestamp'` |
| Service not accessible | Verify service endpoints: `kubectl get endpoints` |

### Useful Debugging Commands

```bash
# Get cluster events
kubectl get events --sort-by='.lastTimestamp'

# Check node resources
kubectl describe nodes

# Check pod details
kubectl describe pod nginx-test

# Check service endpoints
kubectl get endpoints nginx-test-service
```

---

## Cost Considerations

| Resource | Estimated Cost |
|----------|----------------|
| EKS Control Plane | ~$0.10/hour |
| t3.small node | ~$0.02/hour |
| NAT Gateway | ~$0.045/hour + data transfer |

**Tip:** Delete the cluster immediately after testing to minimize costs.

---

## Files in This Project

| File | Description |
|------|-------------|
| `EKS-SETUP-PLAN.md` | This setup guide |
| `nginx-test-pod.yaml` | Kubernetes manifest for nginx test pod and service |
| `eksctl-cluster-config.yaml` | (Optional) eksctl cluster configuration file |

---

## Next Steps (Optional Enhancements)

- Add an Ingress controller for external access
- Implement Horizontal Pod Autoscaler (HPA)
- Set up monitoring with CloudWatch or Prometheus
- Configure RBAC for team access
- Add network policies for security
