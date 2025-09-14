resource "kubernetes_namespace" "navidrome" {
  metadata {
    name = "navidrome"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "music_data" {
  metadata {
    name      = "music-data"
    namespace = kubernetes_namespace.navidrome.id
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "30G"
      }
    }

    storage_class_name = "longhorn"
  }

}

resource "helm_release" "navidrome" {
  name       = "navidrome"
  repository = "https://namnd.github.io/helm-charts"
  chart      = "navidrome"
  version    = "0.1.0"

  create_namespace = false
  namespace        = kubernetes_namespace.navidrome.id

  set = [
    {
      name  = "persistence.enabled"
      value = true
    },
    {
      name  = "persistence.music.existingClaim"
      value = kubernetes_persistent_volume_claim_v1.music_data.metadata[0].name
    },
  ]
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "navidrome" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  account_id = local.cloudflare_account_id

  config = {
    ingress = [
      {
        hostname = "audio.${data.cloudflare_zone.this.name}"
        service  = "http://${helm_release.navidrome.name}.${helm_release.navidrome.namespace}.svc.cluster.local:4533"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "cloudflare_dns_record" "navidrome" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "audio.${data.cloudflare_zone.this.name}"
  ttl     = 1
  proxied = true
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}
