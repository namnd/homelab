cluster_endpoint = "192.168.0.156"

control_plane_nodes = {
  "192.168.0.156" = {
    machine = {
      install = {
        disk = "/dev/sdc"
      }
    }
  }
}

worker_nodes = {
  "192.168.0.118" = {}
  "192.168.0.152" = {}

  "192.168.0.84" = {
    machine = {
      install = {
        disk = "/dev/nvme0n1"
      }
    }
  }
}
