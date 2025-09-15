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

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  account_id = local.cloudflare_account_id

  config = {
    ingress = [
      {
        hostname = cloudflare_dns_record.navidrome.name
        service  = "http://${helm_release.navidrome.name}.${helm_release.navidrome.namespace}.svc.cluster.local:4533"
      },
      {
        hostname = cloudflare_dns_record.youtube_dl.name
        service  = "http://${helm_release.youtube_dl.name}.${helm_release.navidrome.namespace}.svc.cluster.local:8080"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "cloudflare_zero_trust_access_policy" "youtube_dl_access_policy" {
  account_id = local.cloudflare_account_id
  name       = "homelab"

  decision         = "allow"
  session_duration = "24h"
  include = [
    {
      email = {
        email = "me@namnd.com"
      },
    },
    {
      email = {
        email = "namnd86@gmail.com"
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_application" "youtube_dl" {
  account_id = local.cloudflare_account_id
  name       = "homelab"
  type       = "self_hosted"

  destinations = [{
    type = "public"
    uri  = cloudflare_dns_record.youtube_dl.name
  }]
  session_duration           = "168h"
  allowed_idps               = ["d7fef9ee-ff2c-4be4-930c-a86b416f8e41"] # Github
  auto_redirect_to_identity  = true
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  options_preflight_bypass   = false

  policies = [{
    id         = cloudflare_zero_trust_access_policy.youtube_dl_access_policy.id
    precedence = 1
  }]
}
