terraform {
  backend "s3" {
    bucket       = "namnd-homelab-2026"
    key          = "03-system.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = "namnd-homelab-2026"
    key    = "02-cluster.tfstate"
    region = "ap-southeast-2"
  }
}

provider "kubernetes" {
  config_path = data.terraform_remote_state.cluster.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = data.terraform_remote_state.cluster.outputs.kubeconfig_path
  }
}

