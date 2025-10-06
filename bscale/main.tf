terraform {
  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "bscale.tfstate"
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
  namespace             = "bscale"
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

