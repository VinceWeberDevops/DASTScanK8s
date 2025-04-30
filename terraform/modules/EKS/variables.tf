###############################################################################
# AWS EKS Infrastructure Variables
###############################################################################

#------------------------------------------------------------------------------
# AWS Region Configuration
#------------------------------------------------------------------------------
variable "aws_region" {
  description = "The AWS region where EKS resources will be provisioned"
  type        = string
  default     = "eu-west-2"  # London region

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., eu-west-2, us-east-1)"
  }
}

#------------------------------------------------------------------------------
# EKS Cluster Configuration
#------------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster - used as prefix for related resources"
  type        = string
  default     = "dast-scan-eks"

  validation {
    condition     = length(var.cluster_name) >= 3 && length(var.cluster_name) <= 40
    error_message = "Cluster name must be between 3 and 40 characters"
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"

  validation {
    condition     = can(regex("^1\\.(2[5-9]|[3-9][0-9])$", var.cluster_version))
    error_message = "Cluster version must be 1.25 or higher"
  }
}

#------------------------------------------------------------------------------
# VPC and Network Configuration
#------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC that will host the EKS cluster"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block"
  }
}

variable "availability_zones" {
  description = "Availability zones to use for EKS cluster subnets"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets where EKS worker nodes will run"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs are required for high availability"
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets used for load balancers and NAT gateways"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnet CIDRs are required for high availability"
  }
}

#------------------------------------------------------------------------------
# EKS Node Group Configuration
#------------------------------------------------------------------------------
variable "node_group_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.node_group_instance_types) > 0
    error_message = "At least one instance type must be specified"
  }
}

variable "node_group_desired_capacity" {
  description = "Desired number of worker nodes in the EKS cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.node_group_desired_capacity >= 1
    error_message = "Desired capacity must be at least 1"
  }
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes in the EKS cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.node_group_min_size >= 1
    error_message = "Minimum size must be at least 1"
  }
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes in the EKS cluster"
  type        = number
  default     = 4

  validation {
    condition     = var.node_group_max_size >= var.node_group_min_size
    error_message = "Maximum size must be greater than or equal to minimum size"
  }
}

#------------------------------------------------------------------------------
# Resource Tagging
#------------------------------------------------------------------------------
variable "environment" {
  description = "Environment name for resource tagging (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod"
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Local Variables
#------------------------------------------------------------------------------
locals {
  tags = merge(
    {
      Environment = var.environment
      Terraform   = "true"
      Project     = var.cluster_name
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )

  # Validate that we have matching numbers of subnets and availability zones
  validate_subnet_az_count = length(var.private_subnet_cidrs) == length(var.availability_zones) ? true : tobool("Number of private subnets must match number of availability zones")
  validate_public_subnet_az_count = length(var.public_subnet_cidrs) == length(var.availability_zones) ? true : tobool("Number of public subnets must match number of availability zones")
}