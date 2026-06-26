terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.4"
    }

    virtualbox = {
      source  = "namnd/virtualbox"
      version = "0.2.4"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.0"

    }
  }

  backend "s3" {
    bucket       = "namnd-homelab-2026"
    key          = "01-node.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "virtualbox" {}
provider "local" {}
