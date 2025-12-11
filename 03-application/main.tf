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

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = local.tailnet
}

terraform {
  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "03-application.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.22.0"
    }
  }
}

locals {
  cloudflare_account_id = "b45e6b6ab8976d9189ad6e38d29e44b1"
  tailnet               = "tail24c71.ts.net"
}

