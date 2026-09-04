variable "kubeconfig_path" {
  type        = string
  description = "Path to the local kubeconfig file"
  default     = "~/.kube/config"
}

variable "kube_context" {
  type        = string
  description = "Target Kubernetes cluster context"
  default     = "kind-devops-cluster"
}

variable "monitoring_namespace" {
  type        = string
  description = "Kubernetes namespace for the centralized monitoring stack"
  default     = "monitoring"
}

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana web dashboard"
  default     = "REPLACE_WITH_RUNTIME_SECRET"
  sensitive   = true
}

variable "helm_chart_version" {
  type        = string
  description = "Version of the kube-prometheus-stack Helm chart"
  default     = "65.3.1"
}
