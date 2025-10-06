resource "random_password" "tunnel_secret" {
  length           = 32
  override_special = "-_"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id    = local.cloudflare_account_id
  name          = local.namespace
  config_src    = "local"
  tunnel_secret = random_password.tunnel_secret.result
}

resource "helm_release" "cloudflare_tunnel" {
  name       = "cloudflare-tunnel"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflare-tunnel"
  version    = "0.3.2"

  create_namespace = false
  namespace        = local.namespace

  set_sensitive = [
    {
      name  = "cloudflare.account"
      value = local.cloudflare_account_id
    },
    {
      name  = "cloudflare.tunnelName"
      value = local.namespace
    },
    {
      name  = "cloudflare.tunnelId"
      value = cloudflare_zero_trust_tunnel_cloudflared.this.id
    },
    {
      name  = "cloudflare.secret"
      value = random_password.tunnel_secret.result
    },
    {
      name  = "cloudflare.ingress[0].hostname"
      value = "*.bscale.io"
    },
    {
      name  = "cloudflare.ingress[0].service"
      value = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local"
    },
    {
      name  = "cloudflare.ingress[0].originRequest.noTLSVerify"
      value = true
    },
  ]
}

