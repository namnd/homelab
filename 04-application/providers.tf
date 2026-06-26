terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.29.2"
    }
  }

  backend "s3" {
    bucket       = "namnd-homelab-2026"
    key          = "04-application.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "http" {}
provider "tls" {}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = "namnd-homelab-2026"
    key    = "02-cluster.tfstate"
    region = "ap-southeast-2"
  }
}

provider "helm" {
  kubernetes = {
    config_path = data.terraform_remote_state.cluster.outputs.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = data.terraform_remote_state.cluster.outputs.kubeconfig_path
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = "tail24c71.ts.net"
}
