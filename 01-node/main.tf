locals {
  talos_iso_path    = abspath("${path.module}/images/metal-amd64.iso")
  disk_path         = "/data"
  network_interface = "wlp3s0"
  nodes = {
    "cp" = {
      role      = "controlplance"
      cpus      = 2
      memory    = 4096
      disk_size = 20480
      state     = "installed"
    }
    "w1" = {
      role      = "worker"
      cpus      = 4
      memory    = 4096
      disk_size = 256000
      state     = "installed"
    }
    "w2" = {
      role      = "worker"
      cpus      = 4
      memory    = 4096
      disk_size = 256000
      state     = "installed"
    }
    "w3" = {
      role      = "worker"
      cpus      = 4
      memory    = 4096
      disk_size = 256000
      state     = "installed"
    }
    "w4" = {
      role      = "worker"
      cpus      = 4
      memory    = 4096
      disk_size = 256000
      state     = "installed"
    }
  }
}

###############################################################################
# ISO Image - Download directly from Talos Image factory
###############################################################################
data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version
  filters = {
    names = [
      "siderolabs/iscsi-tools",
      "siderolabs/util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

resource "terraform_data" "download_iso_image" {
  triggers_replace = [
    talos_image_factory_schematic.this,
  ]

  input = {
    file = local.talos_iso_path
  }

  provisioner "local-exec" {
    command = <<EOT
      curl https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${var.talos_version}/metal-amd64.iso -L -o ${self.input.file}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm ${self.input.file}"
  }
}

###############################################################################
# Nodes - Virtualbox VM
###############################################################################

resource "virtualbox_disk" "this" {
  for_each = local.nodes

  file_path = "${local.disk_path}/${var.cluster_name}-${each.key}.vdi"
  size      = each.value.disk_size
  format    = "VDI"
}

resource "virtualbox_vm" "this" {
  for_each = local.nodes

  name    = "${var.cluster_name}-${each.key}"
  os_type = "Linux_64"

  cpus   = each.value.cpus
  memory = each.value.memory

  network_adapter {
    type             = "bridged"
    host_interface   = local.network_interface
    promiscuous_mode = "allow-all"
  }

  storage_controller {
    name          = "IDE Controller"
    type          = "ide"
    controller    = "PIIX4"
    host_io_cache = true
  }

  storage_controller {
    name       = "SATA Controller"
    type       = "sata"
    controller = "IntelAHCI"
    port_count = 1
    bootable   = true
  }
}

resource "virtualbox_vm_storage_attachment" "iso_attachment" {
  for_each = { for k, v in virtualbox_vm.this : k => v if local.nodes[k].state != "installed" }

  vm_id           = each.value.id
  controller_name = "IDE Controller"
  port            = 1
  device          = 0
  type            = "dvddrive"
  medium          = local.talos_iso_path

  depends_on = [
    virtualbox_vm.this,
    terraform_data.download_iso_image,
  ]

  lifecycle {
    ignore_changes = all
  }
}

resource "virtualbox_vm_storage_attachment" "hdd_attachment" {
  for_each = virtualbox_vm.this

  vm_id           = each.value.id
  controller_name = "SATA Controller"
  port            = 0
  device          = 0
  type            = "hdd"
  medium          = virtualbox_disk.this[each.key].file_path

  depends_on = [
    virtualbox_vm.this,
    virtualbox_disk.this,
  ]
}

resource "virtualbox_vm_ip_address" "this" {
  for_each = virtualbox_vm.this

  vm_id = each.value.id

  depends_on = [
    virtualbox_vm_storage_attachment.iso_attachment,
    virtualbox_vm_storage_attachment.hdd_attachment,
  ]
}
