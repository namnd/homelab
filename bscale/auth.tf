resource "random_password" "oauth2_cookie_secret" {
  length           = 32
  override_special = "-_"
}

resource "helm_release" "oauth2" {
  name       = "oauth2-proxy"
  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"

  create_namespace = false
  namespace        = local.namespace

  set = [
    {
      name  = "config.cookieSecret"
      value = random_password.oauth2_cookie_secret.result
    },
    {
      name  = "config.provider"
      value = "google"
    },
    {
      name  = "config.clientID"
      value = var.google_client_id
    },
    {
      name  = "config.clientSecret"
      value = var.google_client_secret
    }
  ]
}

resource "kubernetes_ingress_v1" "auth_ingress" {
  metadata {
    name      = "auth"
    namespace = local.namespace
    annotations = {
      "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "true"
      "external-dns.alpha.kubernetes.io/hostname"           = "auth.bscale.io"
      "external-dns.alpha.kubernetes.io/target"             = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "auth.bscale.io"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "oauth2-proxy"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
