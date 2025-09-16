variable "cluster_endpoint" {
  type = string
}

variable "control_plane_nodes" {
  type = map(any)
}

variable "worker_nodes" {
  type = map(any)
}
