variable "control_plane_ip" {
  type = string
}

variable "worker_nodes" {
  type = map(any)
}
