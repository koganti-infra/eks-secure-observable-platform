# Secure, Observable, and Scalable EKS Platform on AWS

This project demonstrates a production-grade EKS setup on AWS using Terraform, GitOps with Argo CD, Istio service mesh, Karpenter autoscaling, a full observability stack, and open-source security tools. It reflects real-world best practices and is structured for scalability and maintainability.

---

## 1. Infrastructure Provisioning (Terraform)

### Files
- `main.tf`: Orchestrates module calls
- `vpc.tf`: VPC, subnets, IGW
- `eks.tf`: EKS cluster and managed node groups
- `karpenter.tf`: Karpenter provisioning
- `iam.tf`: Roles for EKS, Argo CD, and Karpenter

```hcl
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnets         = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      instance_types   = ["t3.medium"]
    }
  }

  enable_irsa = true
  tags        = var.tags
}
```

---

## 2. GitOps with Argo CD

### Argo CD Install (via Helm)
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace
```

### Application CR (sample)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: istio
spec:
  destination:
    namespace: istio-system
    server: https://kubernetes.default.svc
  source:
    repoURL: https://github.com/your-org/platform-configs
    path: istio
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 3. Istio Service Mesh (via Argo CD)
- Enabled mTLS across all services
- Ingress Gateway deployed
- VirtualServices for traffic splitting

```bash
istioctl install --set profile=demo -y
```

Example `VirtualService`:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews.prod.svc.cluster.local
  http:
    - route:
        - destination:
            host: reviews
            subset: v2
```

---

## 4. Karpenter Autoscaler

### Setup
```hcl
module "karpenter" {
  source = "terraform-aws-modules/eks/karpenter/aws"
  cluster_name = module.eks.cluster_name
  tags = var.tags
}
```

### Provisioner Example
```yaml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  requirements:
    - key: "instance-type"
      operator: In
      values: ["t3.medium", "m5.large"]
  limits:
    resources:
      cpu: 1000
```

---

## 5. Observability Stack (via Argo CD)

### Components
- **Prometheus**: metrics collection
- **Grafana**: dashboards
- **Loki**: log aggregation
- **Tempo/Jaeger**: distributed tracing

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install prom grafana/kube-prometheus-stack -n monitoring --create-namespace
```

---

## 6. Microservices Deployment

Three example microservices (Go/Node.js) deployed via Argo CD. All use:
- Istio sidecars for traffic control
- HPA based on CPU usage

### HPA Example
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

---

## 7. Policy Enforcement (Kyverno)

### Sample Policy: Disallow `latest` Tag
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: enforce
  rules:
    - name: validate-image-tag
      match:
        resources:
          kinds: [Pod]
      validate:
        message: "Image tag 'latest' is not allowed."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

---

## 8. Runtime Threat Detection (Falco)

### Setup (Helm)
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace
```

### Alerts to Loki or Slack (via webhook)
```yaml
customRules:
  - rule: Unexpected Shell
    desc: A shell was spawned in a container (unexpected behavior)
    condition: spawned_process and container and shell_procs
    output: "Shell detected (user=%user.name command=%proc.cmdline container=%container.id)"
    priority: WARNING
```

---

## 9. Container Image Scanning (Trivy)

### CI Job Example
```yaml
scan:
  script:
    - trivy image --severity CRITICAL,HIGH your-registry/your-image:tag
```

### Kubernetes CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-scan
spec:
  schedule: "@daily"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: trivy
            image: aquasec/trivy:latest
            args: ["image", "your-image"]
          restartPolicy: OnFailure
```

---

## 10. Secret Detection (Gitleaks)

### Git Hook Setup (pre-commit)
```bash
brew install gitleaks
pre-commit install
```

### GitHub Action
```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Gitleaks Scan
        uses: zricethezav/gitleaks-action@v2.0.0
```

---

## Quickstart Testing Guide

### 1. Terraform Infra (VPC + EKS)
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name eks-secure-observable
kubectl get nodes
```

### 3. Bootstrap Argo CD
```bash
helm repo add argo https://argoproj.github.io/argo-helm                                        ⎈ eks-secure-observable
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace
```

### 4. Argo CD UI Access
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Visit: http://localhost:443

Get password:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
```

### 5. Apply Argo Apps
```bash
kubectl apply -f argo-cd/applications/core-platform.yaml
kubectl apply -f argo-cd/applications/observability.yaml
kubectl apply -f argo-cd/applications/microservice-a.yaml
```

### 6. Validate
```bash
kubectl get all -n istio-system
kubectl get all -n monitoring
kubectl get all -n default
```

### 7. Microservice Access (via Istio Gateway)
```bash
kubectl get svc istio-ingressgateway -n istio-system
curl http://<EXTERNAL-IP>/
```

### 8. Teardown
```bash
terraform destroy
```

