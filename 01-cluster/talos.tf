resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "cp" {
  cluster_name     = "namnd-homelab"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "cp" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cp.machine_configuration
  node                        = var.control_plane_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.cp
  ]
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.control_plane_ip
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

