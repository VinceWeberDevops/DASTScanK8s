###############################################################################
# AWS Infrastructure Variables
###############################################################################

#------------------------------------------------------------------------------
# AWS Region Configuration
#------------------------------------------------------------------------------
variable "aws_region" {
  description = "The AWS region where resources will be provisioned"
  type        = string
  default     = "eu-west-2"  # London region

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., eu-west-2, us-east-1)"
  }
}

#------------------------------------------------------------------------------
# ECR Repository Configuration
#------------------------------------------------------------------------------
variable "reponame" {
  description = "Name of the Elastic Container Registry (ECR) repository"
  type        = string
  default     = "buyggy-repository"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.reponame))
    error_message = "ECR repository name must be between 2 and 256 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen"
  }
}