variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "7.7.10"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.argocd_namespace
  create_namespace = true
  wait             = true

  values = [
    <<-YAML
      server:
        service:
          type: ClusterIP
    YAML
  ]
}

output "argocd_release_status" { value = helm_release.argocd.status }
output "argocd_namespace" { value = helm_release.argocd.namespace }
