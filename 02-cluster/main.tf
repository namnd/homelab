data "terraform_remote_state" "nodes" {
  backend = "s3"

  config = {
    bucket = "namnd-homelab-2026"
    key    = "01-node.tfstate"
    region = "ap-southeast-2"
  }
}

locals {
  control_plane_ip = data.terraform_remote_state.nodes.outputs.control_plane_ip
  worker_ips       = data.terraform_remote_state.nodes.outputs.worker_ips
  image            = format("factory.talos.dev/metal-installer/%s:%s", data.terraform_remote_state.nodes.outputs.talos_image_factory_schematic_id, var.talos_version)
  kubeconfig_path  = pathexpand("~/.kube/config-${var.cluster_name}")
}

resource "talos_machine_secrets" "this" {}

###############################################################################
# Control plane - Make sure to (manually) start node before hand
###############################################################################

data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "control_plane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = local.control_plane_ip
}

resource "talos_machine_bootstrap" "control_plane" {
  node                 = local.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

###############################################################################
# Worker nodes(s) - Make sure to (manually) start nodes before hand
###############################################################################
data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = data.talos_machine_configuration.control_plane.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = toset(local.worker_ips)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.key

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = local.image
        }
        kubelet = {
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options = [
                "bind",
                "rshared",
                "rw",
              ]
            }
          ]
        }
      }
    })
  ]
}

###############################################################################
# Kube config
###############################################################################

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.control_plane
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.control_plane_ip
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = local.kubeconfig_path
}
