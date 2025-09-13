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

terraform {
  backend "s3" {
    bucket       = "namnd-homelab"
    key          = "02-system.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}
