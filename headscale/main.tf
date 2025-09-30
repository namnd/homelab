terraform {
  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "headscale.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = "ap-sydney-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  namespace             = "headscale"
  cloudflare_account_id = "b45e6b6ab8976d9189ad6e38d29e44b1"
}

