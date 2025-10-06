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

