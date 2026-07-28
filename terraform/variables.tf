variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Name used for Hetzner resources"
  type        = string
  default     = "ipgeo-platform"
}

variable "location" {
  description = "Hetzner location"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "Hetzner server type for all Kubernetes nodes"
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "Server image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_public_key_path" {
  description = "Public SSH key used for the nodes"
  type        = string
  default     = "~/.ssh/ipgeo-platform.pub"
}

variable "admin_cidr" {
  description = "Public IP of the management server with /32"
  type        = string
}

variable "network_cidr" {
  description = "Private network range"
  type        = string
  default     = "10.10.0.0/24"
}
