resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.0.0"

  create_namespace = false
  namespace        = kubernetes_namespace.monitoring.id

  set = [
    {
      name  = "persistence.enabled"
      value = true
    }
  ]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "27.37.0"

  create_namespace = false
  namespace        = kubernetes_namespace.monitoring.id
}
