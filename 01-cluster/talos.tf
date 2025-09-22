resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "this" {
  cluster_name     = "namnd-homelab"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "control_plane" {
  for_each = var.control_plane_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  node                        = each.key

  config_patches = [
    yamlencode(provider::deepmerge::mergo({}, each.value))
  ]
}

resource "talos_machine_bootstrap" "this" {
  for_each = var.control_plane_nodes

  depends_on = [
    talos_machine_configuration_apply.control_plane
  ]
  node                 = each.key
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.cluster_endpoint
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = pathexpand("~/.kube/config")
}

# Worker nodes

data "talos_machine_configuration" "worker" {
  cluster_name     = data.talos_machine_configuration.this.cluster_name
  machine_type     = "worker"
  cluster_endpoint = data.talos_machine_configuration.this.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = var.worker_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.key

  config_patches = [
    yamlencode(provider::deepmerge::mergo({
      machine = {
        install = {
          image = "factory.talos.dev/metal-installer/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245:v1.11.1"
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
    }, each.value))
  ]
}

