###############################################################################
# AWS Infrastructure Variables Configuration
###############################################################################

#------------------------------------------------------------------------------
# AWS Region Configuration
#------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-west-2" 
}

#------------------------------------------------------------------------------
# VPC Configuration
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
  default     = "vpc-07bf64e1ac4251762"  
}

variable "cidr_block" {
  description = "CIDR block for the VPC network configuration"
  type        = string
  default     = "172.31.0.0/16"
}

#------------------------------------------------------------------------------
# SSH Key Configuration
#------------------------------------------------------------------------------
variable "key_name" {
  description = "Name of the SSH key pair for EC2 instance access"
  type        = string
  default     = "JenkinsMaster"  
}