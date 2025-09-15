terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0-alpha.0"
    }
    deepmerge = {
      source = "isometry/deepmerge"
    }
  }

  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "01-cluster.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "deepmerge" {}
