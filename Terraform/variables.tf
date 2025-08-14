variable "project_name" {

  description = "my project name"
  type        = string
}

variable "project_environment" {

  description = "my project environment"
  type        = string
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
}

variable "ami_id" {
  description = "ami id"
  type        = string
}

variable "domain_name" {

  description = "domain name"
  type        = string
}

variable "hostname" {

  description = "my hostname"
  type        = string

}

variable "vpc_cidr_block" {

  description = "vpc cidr block"
  type        = string
}

variable "enable_nat_gw" {

  description = "Set true to enable nat gw"
  type        = bool
}

variable "loadbalancer_ports" {

  description = "loadbalancer ports"
  type        = list(string)
}
