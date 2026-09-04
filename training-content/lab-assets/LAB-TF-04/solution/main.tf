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
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout         = 600
  wait            = true
  cleanup_on_fail = true

  values = [
    file("${path.module}/values-monitoring.yaml")
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# 3. Output Useful Endpoints & Credentials
output "monitoring_namespace" {
  value       = kubernetes_namespace.monitoring.metadata[0].name
  description = "The namespace where monitoring stack is deployed"
}

output "helm_release_status" {
  value       = helm_release.kube_prometheus_stack.status
  description = "Status of the Helm release"
}

output "grafana_access_info" {
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/kube-prometheus-stack-grafana 3000:80"
  description = "Command to access Grafana UI locally"
}

output "prometheus_access_info" {
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/kube-prometheus-stack-prometheus 9090:9090"
  description = "Command to access Prometheus UI locally"
}
