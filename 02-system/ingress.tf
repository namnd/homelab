resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.0"

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

