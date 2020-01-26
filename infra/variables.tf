variable "ssh_pubkey_path" {
  description = "Path to SSH public key to be deployed on instances"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "List of CIDR blocks from where to allow SSH access"
  type        = list(string)
}
