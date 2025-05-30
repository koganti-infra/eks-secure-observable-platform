data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  namespace  = "karpenter"
  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter.arn
  }

  set {
    name  = "controller.env[0].name"
    value = "CLUSTER_NAME"
  }

  set {
    name  = "controller.env[0].value"
    value = module.eks.cluster_name
  }

  set {
    name  = "controller.env[1].name"
    value = "CLUSTER_ENDPOINT"
  }

  set {
    name  = "controller.env[1].value"
    value = module.eks.cluster_endpoint
  }

  depends_on = [module.eks]
}
