resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-key"
    namespace = local.namespace
  }

  data = {
    "apiKey" = var.cloudflare_api_token
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"

  namespace        = local.namespace
  create_namespace = false

  set = [
    {
      name  = "sources[0]"
      value = "ingress"
    },
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "provider.name"
      value = "cloudflare"
    },
    {
      name  = "env[0].name"
      value = "CF_API_TOKEN"
    },
    {
      name  = "env[0].valueFrom.secretKeyRef.name"
      value = kubernetes_secret.cloudflare_api_key.metadata[0].name
    },
    {
      name  = "env[0].valueFrom.secretKeyRef.key"
      value = "apiKey"
    },
  ]

}

