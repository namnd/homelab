terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.4"
    }

    deepmerge = {
      source = "isometry/deepmerge"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }

  }

  backend "s3" {
    bucket       = "namnd-homelab-2026"
    key          = "02-cluster.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "deepmerge" {}
provider "local" {}
