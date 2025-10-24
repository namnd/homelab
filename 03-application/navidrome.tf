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

resource "kubernetes_ingress_v1" "navidrome_ingress" {
  metadata {
    name      = "navidrome"
    namespace = kubernetes_namespace.navidrome.id
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "audio.namnd.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "navidrome"
              port {
                number = 4533
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map_v1" "youtube_dl_config" {
  metadata {
    name      = "youtube-dl-config"
    namespace = kubernetes_namespace.navidrome.id
  }

  data = {
    "args.conf"    = file("${path.module}/youtube-dl-config/args.conf")
    "channels.txt" = file("${path.module}/youtube-dl-config/channels.txt")
  }
}

resource "helm_release" "youtube_dl" {
  name       = "youtube-dl"
  repository = "https://namnd.github.io/helm-charts"
  chart      = "youtube-dl"
  version    = "0.2.0"

  create_namespace = false
  namespace        = kubernetes_namespace.navidrome.id

  set = [
    {
      name  = "image.tag"
      value = "v2025.10.22"
    },
    {
      name  = "env[0].name"
      value = "youtubedl_webui"
    },
    {
      name  = "env[0].value"
      value = "true"
    },
    {
      name  = "persistence.enabled"
      value = true
    },
    {
      name  = "persistence.downloads.existingClaim"
      value = kubernetes_persistent_volume_claim_v1.music_data.metadata[0].name
    },
    {
      name  = "config.enabled"
      value = true
    },
    {
      name  = "config.configMap"
      value = kubernetes_config_map_v1.youtube_dl_config.metadata[0].name
    },
  ]
}

resource "kubernetes_ingress_v1" "youtube_dl_ingress" {
  metadata {
    name      = "youtube-dl"
    namespace = kubernetes_namespace.navidrome.id
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "y.namnd.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "youtube-dl"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

