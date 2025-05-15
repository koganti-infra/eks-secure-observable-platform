# Secure, Observable, and Scalable EKS Platform on AWS

This project sets up a production-grade Amazon EKS environment using:

- **Terraform** for infrastructure provisioning
- **Argo CD** for GitOps workflows
- **Istio** for service mesh and secure traffic routing
- **Karpenter** for dynamic node autoscaling
- **Prometheus, Grafana, Loki** for observability
- **Kyverno, Falco, Trivy** for policy enforcement and container security
- **Node.js microservice** to demonstrate deployment, autoscaling, and Istio routing

---

## Tech Stack

| Component       | Tool(s)                             |
|----------------|-------------------------------------|
| Infrastructure | Terraform, AWS VPC, EKS             |
| GitOps         | Argo CD                             |
| Service Mesh   | Istio                               |
| Autoscaling    | Karpenter                           |
| Observability  | Prometheus, Grafana, Loki           |
| Microservices  | Node.js, Kubernetes, HPA            |
| Policy Control | Kyverno                             |
| Runtime Sec    | Falco                                |
| Image Scanning | Trivy                               |

---

## Folder Structure

```bash
.
├── terraform/                # Infra setup
├── argo-cd/                  # GitOps setup and apps
├── istio/                    # Istio base and routing
├── observability/           # Prometheus + Grafana config
├── microservices/service-a/ # Sample Node.js microservice
├── policies/kyverno/        # Kyverno policy YAMLs
├── security/                # Falco and Trivy configs
├── README.md
└── docs/architecture.md     # System design and flow
