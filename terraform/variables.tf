########################################
# OPTIONAL
########################################
variable "aws_region" {
    type = string
    default = "eu-west-2"
}

variable "vpc_id" {
    type = string
    default = "vpc-07bf64e1ac4251762"
}

variable "key_name" {
    type = string
    default = "JenkinsMaster"
}

variable "cidr_block" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "172.31.0.0/16"
}