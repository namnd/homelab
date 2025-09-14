locals {
  cloudflare_account_id = "b45e6b6ab8976d9189ad6e38d29e44b1"
}

data "cloudflare_zone" "this" {
  filter = {
    account = {
      id = local.cloudflare_account_id
    }
    name = "namnd.com"
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = local.cloudflare_account_id
  name       = "namnd-homelab"
  config_src = "cloudflare"
}

data "http" "tunnel_token" {
  url = "https://api.cloudflare.com/client/v4/accounts/${local.cloudflare_account_id}/cfd_tunnel/${cloudflare_zero_trust_tunnel_cloudflared.this.id}/token"

  request_headers = {
    "Authorization" = "Bearer ${var.cloudflare_api_token}"
    "Content-Type"  = "application/json"
  }
}

resource "helm_release" "cloudflare_tunnel" {
  name       = "cloudflare-tunnel-remote"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflare-tunnel-remote"
  version    = "0.1.2"

  create_namespace = true
  namespace        = "cloudflare"

  set_sensitive = [
    {
      name  = "cloudflare.tunnel_token"
      value = jsondecode(data.http.tunnel_token.response_body)["result"]
    },
  ]

}

resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-key"
    namespace = helm_release.cloudflare_tunnel.namespace
  }

  data = {
    apiKey = var.cloudflare_api_token
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.18.0"

  create_namespace = false
  namespace        = helm_release.cloudflare_tunnel.namespace

  set_list = [
    {
      name  = "sources"
      value = ["ingress"]
    }
  ]

  set = [
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
      value = "cloudflare-api-key"
    },
    {
      name  = "env[0].valueFrom.secretKeyRef.key"
      value = "apiKey"
    },
  ]
}
