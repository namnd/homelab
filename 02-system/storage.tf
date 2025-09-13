resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.9.1"

  create_namespace = true
  namespace        = kubernetes_namespace.longhorn.id
}
