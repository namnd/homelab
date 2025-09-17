resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
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
