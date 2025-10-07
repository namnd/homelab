data "cloudflare_zone" "this" {
  filter = {
    account = {
      id = local.cloudflare_account_id
    }
    name = "bscale.io"
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = local.cloudflare_account_id
  name       = local.namespace
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

  create_namespace = false
  namespace        = local.namespace

  set_sensitive = [
    {
      name  = "cloudflare.tunnel_token"
      value = jsondecode(data.http.tunnel_token.response_body)["result"]
    },
  ]
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "*.${data.cloudflare_zone.this.name}"
  ttl     = 1
  proxied = true
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  account_id = local.cloudflare_account_id

  config = {
    ingress = [
      {
        hostname = "*.${data.cloudflare_zone.this.name}",
        service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local",
        origin_request = {
          no_tls_verify = true
        }
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
