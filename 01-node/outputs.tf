output "control_plane_ip" {
  value = virtualbox_vm_ip_address.this["cp"].ip_address
}

output "worker_ips" {
  value = [for k, v in local.nodes : virtualbox_vm_ip_address.this[k].ip_address if v.role == "worker"]
}

output "talos_image_factory_schematic_id" {
  value = talos_image_factory_schematic.this.id
}
