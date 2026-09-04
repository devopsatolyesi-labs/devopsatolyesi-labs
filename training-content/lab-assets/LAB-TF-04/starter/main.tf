# LAB-TF-04 Starter main.tf
# Complete the resources below to deploy Centralized Monitoring

# 1. Create Dedicated Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = {
      name        = var.monitoring_namespace
      managed-by  = "terraform"
      environment = "training"
    }
  }
}

# 2. Deploy Centralized Monitoring via Helm Release
# TODO: Define the helm_release resource with chart 'kube-prometheus-stack'
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values-monitoring.yaml")
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [kubernetes_namespace.monitoring]
}
