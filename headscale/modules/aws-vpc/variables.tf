variable "name" {
  description = "The name of the VPC (try to be as unique as possible, e.g. <namespace>-<env>-<service>)"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "The number of availability zones to use."
  type        = number
  default     = 1
}
