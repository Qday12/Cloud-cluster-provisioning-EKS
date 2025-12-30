aws configure

eksctl create cluster -f eksctl-cluster-config.yaml

---
# Update kubeconfig (if needed)
aws eks update-kubeconfig --region eu-central-1 --name eks-test-cluster

# Verify cluster connection
kubectl cluster-info

# Check nodes are ready
kubectl get nodes

# Verify all system pods are running
kubectl get pods -n kube-system
---


# Apply the nginx test pod configuration
kubectl apply -f nginx-test-pod.yaml

# Watch the pod status
kubectl get pods -w

# Run a temporary curl pod
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://nginx-test-service:80
```bash
[qday@archlinux Cloud-cluster-provisioning-EKS]$ kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl http://nginx-test-service:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
pod "curl-test" deleted from default namespace
```
---
# Cleaning
eksctl delete cluster --name eks-test-cluster --region eu-central-1