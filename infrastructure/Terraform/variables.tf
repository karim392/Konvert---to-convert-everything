# Project name
variable "project_name" {
  type = string
}

# VPC CIDR block
variable "vpc_cidr" {
  type = string
}

# Public Subnet CIDR block
variable "public_subnet_cidr" {
  type = list(string)
}

# Private Subnet CIDR block
variable "private_subnet_cidr" {
  type = list(string)
}

# DB username and password
variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

# EC2 instance type
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# AMI ID for EC2 instances
variable "ami_id" {
  type = string

} 