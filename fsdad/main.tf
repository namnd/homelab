terraform {
  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "fsdad.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.11.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  namespace             = "fsdad"
  cloudflare_account_id = "b45e6b6ab8976d9189ad6e38d29e44b1"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = local.namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "url_scraper" {
  name       = "url-scraper"
  repository = "https://namnd.github.io/helm-charts"
  chart      = "url-scraper"
  version    = "0.1.0"

  create_namespace = false
  namespace        = local.namespace

  set = [
    {
      name  = "cloudflareApiToken"
      value = var.cloudflare_api_token
    },
    {
      name  = "service.port"
      value = "8080"
    }
  ]
}

resource "kubernetes_ingress_v1" "url_scraper_ingress" {
  metadata {
    name      = "submit"
    namespace = local.namespace
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "submit.fsdad.com"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "url-scraper"
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
