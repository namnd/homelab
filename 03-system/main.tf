###############################################################################
# Certificates
###############################################################################
resource "helm_release" "cert" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.18.2"

  create_namespace = true
  namespace        = "cert-manager"

  set = [
    {
      name  = "crds.enabled"
      value = true
    },
    {
      name  = "global.leaderElection.namespace"
      value = "cert-manager"
    }
  ]
}

###############################################################################
# Ingress
###############################################################################

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.15.1"

  create_namespace = true
  namespace        = "ingress-nginx"

  set = [
    {
      # Type of the external controller service.
      # Ref: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
      # Since we will be using Cloudflare Tunnels, it is sufficient to keep nginx exposed with a ClusterIP
      name  = "controller.service.type"
      value = "ClusterIP"
    },
  ]
}

###############################################################################
# Storage
###############################################################################

resource "kubernetes_namespace_v1" "longhorn" {
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
  version    = "1.12.0"

  create_namespace = false
  namespace        = kubernetes_namespace_v1.longhorn.id
}
