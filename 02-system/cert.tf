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
